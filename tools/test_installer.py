"""Installer acceptance: real file copy, preserve vendor files, exact rollback."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import install_cyberpunk as installer


class InstallerTest(unittest.TestCase):
    def test_install_and_restore(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            game = root/'game/bin/x64'
            game.mkdir(parents=True)
            old = {'Cyberpunk2077.exe': b'game', 'dxgi.dll': b'opti',
                   'OptiScaler.ini': b'[Upscalers]\nDx12Upscaler=fsr31\n',
                   'amd_fidelityfx_upscaler_dx12.dll': b'keep-xmx',
                   'libxess_fg.dll': b'keep-fg', 'nrvk_bridge.dll': b'old-nr'}
            for name, data in old.items():
                (game/name).write_bytes(data)
            full, small = root/'full', root/'small'
            for package, key in ((full, '102'), (small, 'small')):
                (package/'manifest').mkdir(parents=True)
                (package/'manifest/port_network_manifest.json').write_text(json.dumps({'backend_key': key}))
                (package/'manifest/port_network_runtime.txt').write_text('plan')
                (package/'bin').mkdir()
                (package/'bin/nrvk_bridge.dll').write_bytes(key.encode())
            (full/'panel').mkdir()
            (full/'panel/nr_control_panel.py').write_text('# panel')
            (full/'game-files/plugins').mkdir(parents=True)
            for name in ('CyberpunkNRBridge.asi', 'nr_hdr_proxy.hlsl', 'NRB-deferred-identity.enable'):
                (full/'game-files/plugins'/name).write_text(name)
            with patch.object(installer, 'require_game_closed'), patch.object(installer, 'download', side_effect=AssertionError('must preserve installed OptiScaler')):
                receipt = installer.install(game, full, small, root/'cache', '7z', True)
                self.assertEqual((game/'nrvk_bridge.dll').read_bytes(), b'102')
                self.assertIn('input_height = 0', (receipt.parent/'config/nr_panel.ini').read_text())
                self.assertIn(str(small/'manifest'), (receipt.parent/'config/nr_panel.ini').read_text())
                for name in ('dxgi.dll', 'OptiScaler.ini', 'amd_fidelityfx_upscaler_dx12.dll', 'libxess_fg.dll'):
                    self.assertEqual((game/name).read_bytes(), old[name])
                installer.restore(receipt)
                self.assertEqual({p.relative_to(game).as_posix(): p.read_bytes() for p in game.rglob('*') if p.is_file()}, old)


if __name__ == '__main__':
    unittest.main()
