"""CPU/loopback test of the published panel and its shared configuration."""
from pathlib import Path
import argparse
import configparser
import importlib.util
import json
import os
import threading
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def run(output):
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    config = {'ini': str(output/'nr_panel.ini'), 'state': str(output/'panel_state.json'),
              'manifest': str(output/'manifest'), 'optiscaler_ini': str(output/'OptiScaler.ini')}
    cfg = output/'panel-config.json'
    cfg.write_text(json.dumps(config), encoding='utf-8')
    Path(config['state']).write_text('{"backend":"small","mounted":1,"processed":7}', encoding='utf-8')
    os.environ['NR_PANEL_CONFIG'] = str(cfg)
    spec = importlib.util.spec_from_file_location('nr_panel_tested', ROOT/'panel/nr_control_panel.py')
    panel = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(panel)
    panel.save(dict(panel.DEFAULTS))
    server = panel.ThreadingHTTPServer(('127.0.0.1', 0), panel.Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base = 'http://127.0.0.1:' + str(server.server_port)
    try:
        with urllib.request.urlopen(base+'/') as response:
            assert '<option value=102>' not in response.read().decode()
        panel.VK102 = str(output/'vk102/manifest')
        with urllib.request.urlopen(base+'/') as response:
            assert '<option value=102>VK102 310.8</option>' in response.read().decode()
        with urllib.request.urlopen(base+'/status') as response:
            status = json.load(response)
            assert status['state']['processed'] == 7
        payload = json.dumps({'style': 2, 'intensity': 0.7}).encode()
        request = urllib.request.Request(base+'/api', payload, {'Content-Type': 'application/json'})
        try:
            urllib.request.urlopen(request)
            raise AssertionError('POST without token was accepted')
        except urllib.error.HTTPError as exc:
            assert exc.code == 403
        request.add_header('X-NR-Token', panel.TOKEN)
        with urllib.request.urlopen(request) as response:
            assert json.load(response)['style'] == 2
        assert panel.load()['intensity'] == 0.7
        for backend in ('102', 'small'):
            request = urllib.request.Request(base+'/api', json.dumps({'backend': backend}).encode(),
                {'Content-Type': 'application/json', 'X-NR-Token': panel.TOKEN})
            with urllib.request.urlopen(request) as response:
                assert json.load(response)['backend'] == backend
            controls = configparser.ConfigParser()
            controls.read(config['ini'], encoding='utf-8')
            assert controls['Backends']['102'] == panel.VK102
            assert panel.load()['style'] == 2 and panel.load()['intensity'] == 0.7
        assert Path(config['ini']).is_file()
        assert json.loads(Path(config['state']).read_text())['processed'] == 7
    finally:
        server.shutdown()
        server.server_close()
        thread.join()
    (output/'result.json').write_text(json.dumps({'status': 'PASS', 'loopback_only': True,
        'unauthorized_post_rejected': True, 'shared_ini_roundtrip': True,
        'bridge_state_not_overwritten': True, 'optional_vk102_selection_roundtrip': True})+'\n', encoding='utf-8')
    print('PANEL_CPU_PASS: shared paths, state, token, settings roundtrip')


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', type=Path, required=True)
    run(p.parse_args().out)
