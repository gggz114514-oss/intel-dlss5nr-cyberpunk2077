"""Download fixed model containers and verify DLL identities before extraction.

DLLs are parsed as data, never executed. Full's community mirror and Small's
NVIDIA Packman distribution are listed explicitly; no floating latest URLs.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import zipfile
from install_cyberpunk import download, sha

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    'full': ('https://github.com/RankFTW/rhi-repo/releases/download/dlssnr-310.8.0/nvngx_dlssnr_310.8.0.zip',
             '388c0a7912e15ec911b9c9e11a692142b11fe387ddf2b637d8c358138fffb3ac', 'full.zip'),
    'small': ('https://d1oqksizpb0e3d.cloudfront.net/rtx-remix-ngx_sdk_dlnr@2.7z',
              '4bb8651b3ac2180f23df1f39422c489810a13d445a94dc836c876c18c93ecefe', 'small.7z')}


def fetch(out, seven_zip, full=None, small=None):
    out = Path(out).resolve()
    profiles = json.loads((ROOT/'tools/model_profiles.json').read_text(encoding='utf-8'))
    result = {}
    for name, profile, supplied in (('full', 'vk102', full), ('small', 'small', small)):
        if supplied:
            candidates = [Path(supplied).resolve()]
        else:
            url, digest, filename = SOURCES[name]
            archive = download(url, out/filename, digest)
            target = out/name
            target.mkdir(parents=True, exist_ok=True)
            if filename.endswith('.zip'):
                with zipfile.ZipFile(archive) as z:
                    for entry in z.infolist():
                        if Path(entry.filename).name.lower() == 'nvngx_dlssnr.dll':
                            with z.open(entry) as src, (target/'nvngx_dlssnr.dll').open('wb') as dst:
                                shutil.copyfileobj(src, dst)
            else:
                subprocess.run([seven_zip, 'x', str(archive), '-o'+str(target), '-y'], check=True)
            candidates = list(target.rglob('nvngx_dlssnr.dll'))
        expected = [profiles[profile]['dll_sha256'], *profiles[profile].get('equivalent_dll_sha256', [])]
        accepted = [p for p in candidates if sha(p) in expected]
        if len(accepted) != 1:
            raise ValueError(f'{name}: expected DLL SHA256 {expected}. Supply the matching DLL with --{name}; never substitute a same-version different model.')
        result[name] = str(accepted[0])
    out.mkdir(parents=True, exist_ok=True)
    (out/'models.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', required=True)
    p.add_argument('--seven-zip', default='7z')
    p.add_argument('--full')
    p.add_argument('--small')
    a = p.parse_args()
    print(json.dumps(fetch(a.out, a.seven_zip, a.full, a.small), indent=2))
