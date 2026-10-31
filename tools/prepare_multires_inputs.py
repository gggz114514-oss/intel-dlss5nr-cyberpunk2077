"""Write deterministic FP32 LDR/color, native-pixel MV and depth GPU inputs; CPU only."""
import argparse
import array
import hashlib
import json
from pathlib import Path


def prepare(width, height, output):
    output.mkdir(parents=True, exist_ok=False)
    names = ('port_queue_backend_component_color.bin', 'port_queue_backend_component_motion.bin',
             'port_queue_backend_component_depth.bin')
    files = [open(output / name, 'wb') for name in names]
    try:
        motion = array.array('f', [2.0, -1.0] * width).tobytes()
        for y in range(height):
            color = array.array('f')
            depth = array.array('f')
            for x in range(width):
                check = ((x // 7) + (y // 7)) & 1
                color.extend((0.15 + 0.5 * x / width, 0.2 + 0.45 * y / height,
                              0.25 + 0.4 * check, 1.0))
                depth.append(0.2 + 0.6 * x / width)
            files[0].write(color.tobytes())
            files[1].write(motion)
            files[2].write(depth.tobytes())
    finally:
        for file in files:
            file.close()
    receipt = {'scope': 'CPU-created synthetic shader-domain inputs; no sRGB/PNG conversion; no GPU',
               'render': [width, height], 'motion': 'constant (+2,-1) R pixels',
               'files': {name: {'bytes': (output/name).stat().st_size,
                                'sha256': hashlib.file_digest(open(output/name, 'rb'), 'sha256').hexdigest()}
                         for name in names}}
    (output/'INPUTS.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--width', type=int, required=True)
    parser.add_argument('--height', type=int, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.width, args.height, args.out)
