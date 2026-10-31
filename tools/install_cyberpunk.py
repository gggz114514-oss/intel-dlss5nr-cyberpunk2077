"""Install locally built Full/Small packages; fetch OptiScaler only if absent.

Never installs FSR XMX. Existing SR/FG libraries and settings are preserved.
Run through Install-Cyberpunk.cmd, or --help for prepared-package installation.
"""
from pathlib import Path
import argparse
import configparser
import hashlib
import json
import re
import shutil
import subprocess
import urllib.request
from datetime import datetime

OPTI_URL = 'https://github.com/optiscaler/OptiScaler/releases/download/v0.9.4/Optiscaler_0.9.4-final.20260718._MM.7z'
OPTI_SHA = '575cb4df866116093df75af607e37fd70e10f5163e0f23fd5c804142e80ef0ad'


def sha(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def download(url, target, digest):
    target = Path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and sha(target) == digest:
        return target
    temporary = target.with_suffix(target.suffix + '.partial')
    print('Downloading:', url, flush=True)
    request = urllib.request.Request(url, headers={'User-Agent': 'NR-Cyberpunk-Installer'})
    with urllib.request.urlopen(request, timeout=120) as src, temporary.open('wb') as dst:
        shutil.copyfileobj(src, dst)
    if sha(temporary) != digest:
        raise ValueError('Download SHA256 mismatch: ' + url)
    temporary.replace(target)
    return target


def require_game_closed():
    result = subprocess.run(['tasklist', '/FI', 'IMAGENAME eq Cyberpunk2077.exe', '/FO', 'CSV', '/NH'],
                            capture_output=True, check=True)
    if b'cyberpunk2077.exe' in result.stdout.lower():
        raise RuntimeError('Exit Cyberpunk 2077 before installing or restoring.')


def write_ini(path, data):
    cfg = configparser.ConfigParser()
    cfg.read_dict(data)
    with Path(path).open('w', encoding='utf-8') as f:
        cfg.write(f)


def restore(receipt_path):
    require_game_closed()
    receipt_path = Path(receipt_path).resolve()
    data = json.loads(receipt_path.read_text(encoding='utf-8'))
    game = Path(data['game_bin']).resolve()
    for item in reversed(data['files']):
        dst = (game / item['relative']).resolve()
        if not dst.is_relative_to(game):
            raise ValueError('Invalid receipt path')
        if item['existed']:
            shutil.copy2(receipt_path.parent / 'backup' / item['relative'], dst)
        elif dst.exists():
            dst.unlink()
    print('Restored files from', receipt_path)


def install(game, full, small, cache, seven_zip, install_opti=False):
    require_game_closed()
    game, full, small, cache = [Path(p).resolve() for p in (game, full, small, cache)]
    if (game / 'bin/x64/Cyberpunk2077.exe').is_file():
        game = game / 'bin/x64'
    if not (game / 'Cyberpunk2077.exe').is_file():
        raise ValueError('Choose Cyberpunk 2077 root or bin/x64 containing Cyberpunk2077.exe')
    for package, key in ((full, '102'), (small, 'small')):
        for name in ('manifest/port_network_runtime.txt', 'manifest/port_network_manifest.json', 'bin/nrvk_bridge.dll'):
            if not (package / name).is_file():
                raise ValueError('Incomplete package: ' + str(package / name))
        meta = json.loads((package/'manifest/port_network_manifest.json').read_text(encoding='utf-8'))
        if meta['backend_key'] != key:
            raise ValueError('Full/Small package identity reversed')
    for name in ('CyberpunkNRBridge.asi', 'nr_hdr_proxy.hlsl', 'NRB-deferred-identity.enable'):
        if not (full/'game-files/plugins'/name).is_file():
            raise ValueError('Missing bridge asset: ' + name)

    # Download/stage everything before modifying the game.
    copies = {}
    if not (game/'OptiScaler.ini').exists():
        if not install_opti:
            raise ValueError('OptiScaler is missing; rerun with --install-optiscaler to download the fixed official version.')
        if (game/'dxgi.dll').exists():
            raise ValueError('Existing dxgi.dll without OptiScaler.ini: preserve it and resolve the proxy conflict first.')
        archive = download(OPTI_URL, cache/'optiscaler-0.9.4.7z', OPTI_SHA)
        unpack = cache/'optiscaler-0.9.4'
        subprocess.run([seven_zip, 'x', str(archive), '-o'+str(unpack), '-y'], check=True)
        # Do not overwrite game/vendor SR or FG DLLs. No XMX payload is installed.
        for src in unpack.rglob('*'):
            if not src.is_file() or src.suffix.lower() not in ('.dll', '.ini', '.txt', '.md'):
                continue
            relative = src.relative_to(unpack).as_posix()
            if relative == 'OptiScaler.dll':
                relative = 'dxgi.dll'
            if not (game/relative).exists():
                copies[relative] = src
    elif not (game/'dxgi.dll').exists():
        raise ValueError('OptiScaler.ini exists but dxgi.dll is missing; repair the existing installation first.')

    run = cache/'installs'/datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    run.mkdir(parents=True)
    if 'OptiScaler.ini' in copies:
        # Fresh installs must load our ASI. Existing OptiScaler settings remain untouched.
        text = copies['OptiScaler.ini'].read_text(encoding='utf-8-sig')
        for key in ('LoadAsiPlugins', 'ManualInputPolling'):
            text, count = re.subn(r'(?m)^' + key + r'\s*=.*$', key + '=true', text)
            if count != 1:
                raise ValueError('Pinned OptiScaler config key missing or duplicated: ' + key)
        staged_opti = run/'OptiScaler.ini'
        staged_opti.write_text(text, encoding='utf-8')
        copies['OptiScaler.ini'] = staged_opti
    # Keep per-install controls separate so restoring an older bridge restores its own paths too.
    config = run/'config'
    config.mkdir()
    manifests = {'102': str(full/'manifest'), 'small': str(small/'manifest')}
    write_ini(config/'nr_panel.ini', {'NR': {
        'backend': '102', 'enabled': '1', 'input_height': '0', 'style': '0',
        'intensity': '1', 'local_structure': '1', 'local_tone': '0',
        'skin_structure': '0', 'auto_mask': '1', 'display_strength': '1'}, 'Backends': manifests})
    write_ini(run/'nr_bridge.ini', {'bridge': {'backend': '102',
        'manifest_dir': manifests['102'], 'status_json': str(config/'component_status.json'),
        'panel_ini': str(config/'nr_panel.ini'), 'panel_state': str(config/'panel_state.json'), 'tail_profile': '0'}})
    shutil.copytree(full/'panel', run/'panel', ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
    (run/'panel/panel-config.json').write_text(json.dumps({
        'backend': '102', 'backends': manifests, 'manifest': manifests['102'],
        'ini': str(config/'nr_panel.ini'), 'state': str(config/'panel_state.json'),
        'optiscaler_ini': str(game/'OptiScaler.ini')}, indent=2), encoding='utf-8')
    (run/'Open-NR-Panel.cmd').write_text('@echo off\r\npy -3 "%~dp0panel\\nr_control_panel.py"\r\npause\r\n', encoding='ascii')
    for src in (full/'game-files').rglob('*'):
        if src.is_file():
            copies[src.relative_to(full/'game-files').as_posix()] = src
    copies['nrvk_bridge.dll'] = full/'bin/nrvk_bridge.dll'
    copies['plugins/nr_bridge.ini'] = run/'nr_bridge.ini'
    receipt = {'version': 'multires-20261101', 'game_bin': str(game),
               'full': str(full), 'small': str(small), 'status': 'prepared', 'files': []}
    for relative, src in copies.items():
        dst = (game/relative).resolve()
        if not dst.is_relative_to(game):
            raise ValueError('Invalid install path')
        exists = dst.is_file()
        if exists:
            backup = run/'backup'/relative
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, backup)
        receipt['files'].append({'relative': relative, 'existed': exists,
                                 'before_sha256': sha(dst) if exists else None,
                                 'installed_sha256': sha(src)})
    path = run/'INSTALL-RECEIPT.json'
    path.write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    require_game_closed()
    try:
        for relative, src in copies.items():
            dst = game/relative
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
            if sha(src) != sha(dst):
                raise IOError('Install hash mismatch: ' + relative)
    except Exception:
        restore(path)
        raise
    receipt['status'] = 'installed-hash-verified'
    path.write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    print('Installed Full + Small, native input, streaming enabled.')
    print('Keep both package directories and', run)
    print('Panel:', run/'Open-NR-Panel.cmd')
    print('Restore: py -3', Path(__file__).resolve(), '--restore', path)
    return path


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--game')
    p.add_argument('--full')
    p.add_argument('--small')
    p.add_argument('--cache', default=str(Path(__file__).resolve().parents[1]/'local/installer'))
    p.add_argument('--seven-zip', default='7z')
    p.add_argument('--install-optiscaler', action='store_true')
    p.add_argument('--restore', type=Path)
    a = p.parse_args()
    if a.restore:
        restore(a.restore)
    else:
        if not all((a.game, a.full, a.small)):
            p.error('--game, --full and --small are required')
        install(a.game, a.full, a.small, a.cache, a.seven_zip, a.install_optiscaler)
