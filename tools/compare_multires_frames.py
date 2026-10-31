"""Strict CPU comparison for the unchanged 720 GPU path; no image conversion."""
import argparse
import hashlib
import json
from pathlib import Path


def compare(baseline, candidate, receipt):
    rows = []
    for frame in range(7):
        name = f'frame{frame}_out_fp32.bin'
        hashes = []
        for directory in (baseline, candidate):
            with (directory/name).open('rb') as stream:
                hashes.append(hashlib.file_digest(stream, 'sha256').hexdigest())
        rows.append({'frame': frame, 'baseline_sha256': hashes[0],
                     'candidate_sha256': hashes[1], 'bit_exact': hashes[0] == hashes[1]})
    result = {'scope': '720 same-input GPU readbacks; CPU byte comparison; no performance claim',
              'pass': all(row['bit_exact'] for row in rows), 'frames': rows}
    receipt.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print('720_BIT_EXACT_PASS' if result['pass'] else '720_BIT_EXACT_FAIL')
    return 0 if result['pass'] else 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--receipt', type=Path, required=True)
    args = parser.parse_args()
    raise SystemExit(compare(args.baseline, args.candidate, args.receipt))
