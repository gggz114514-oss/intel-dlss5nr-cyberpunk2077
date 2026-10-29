"""Timing analysis for staged ordinary runs (all samples retained, no outlier trimming).

Protocol (book section 3): warm1, reps30, feedback; per arm/process-group mean;
paired process-group differences; two-sided t interval on df = (#groups - 1).
"""
import json, math, statistics, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import receipt_io as K

# two-sided 95% t quantiles
T975 = {1: 12.7062047361747, 2: 4.30265272974946, 3: 3.18244630528426, 4: 2.77644510519779,
        5: 2.570581835636305, 6: 2.44691184879168, 7: 2.3646242510103, 8: 2.30600413520417,
        9: 2.2621571627982, 10: 2.22813885198627, 11: 2.20098516009164}


def load(manifest_path, expect_passes=232, reps=30):
    task = K.read_json(manifest_path)
    groups = {}
    for j in task['jobs']:
        p = Path(j['runner_output'])
        rec = K.read_json(p / 'port_network_receipt.json')
        v = rec['gpu_samples_ms']
        expected = j.get('expected_fixed_frame_out') or j.get('expected_frame_out')
        # the pipeline slims frame binaries after each stage; the hash stays next to the receipt
        if (p / 'frame_out.bin').exists():
            frame_sha = K.sha(p / 'frame_out.bin')
        else:
            fh = p / 'FRAME-HASHES.json'
            frame_sha = (K.read_json(fh).get('frame_out.bin') or {}).get('sha256') if fh.exists() else None
        plan_sha = K.sha(j['plan']['path'])
        checks = dict(normal_close=bool(rec['normal_close']), nan=rec['nan'], inf=rec['inf'],
                      gpu_passes=rec['gpu_passes'], samples=len(v),
                      frame_gold=(frame_sha == expected), plan_sha=(plan_sha == j['plan']['sha256']))
        ok = (checks['normal_close'] and checks['nan'] == 0 and checks['inf'] == 0
              and checks['gpu_passes'] == expect_passes and checks['frame_gold'] and checks['plan_sha'])
        if reps:
            ok = ok and checks['samples'] == reps
        arm = j.get('candidate')
        pair = j.get('pair')
        groups.setdefault((pair, arm), []).append(dict(id=j['id'], mean_ms=statistics.mean(v) if v else None,
                                                       samples_ms=v, ok=ok, checks=checks))
    return task, groups


def compare(groups, arms, label_map):
    """arms = (x, y); saving = mean(x) - mean(y); positive => y faster."""
    x, y = arms
    pairs = sorted({p for (p, a) in groups})
    diffs, xs, ys = [], [], []
    for p in pairs:
        gx = groups.get((p, x), [])
        gy = groups.get((p, y), [])
        if len(gx) != 1 or len(gy) != 1:
            return dict(status='INCOMPLETE', pairs_missing=p, arms=arms)
        if not (gx[0]['ok'] and gy[0]['ok']):
            return dict(status='GATE_FAILED', pair=p, arm_fail=[a for a, g in ((x, gx), (y, gy)) if not g[0]['ok']])
        xs.append(gx[0]['mean_ms']); ys.append(gy[0]['mean_ms'])
        diffs.append(gx[0]['mean_ms'] - gy[0]['mean_ms'])
    n = len(diffs)
    if not 2 <= n <= 12:
        raise ValueError('Use 2..12 paired process groups for the tabulated t interval')
    m = statistics.mean(diffs)
    sd = statistics.stdev(diffs) if n > 1 else 0.0
    h = T975[n - 1] * sd / math.sqrt(n)
    ci = [m - h, m + h]
    status = 'FASTER_95' if ci[0] > 0 else 'SLOWER_95' if ci[1] < 0 else 'INDISTINCT'
    return dict(name='%s_minus_%s' % (label_map.get(x, x), label_map.get(y, y)),
                arms=arms, groups=n, saving_ms=m, CI95_ms=ci,
                group_differences_ms=diffs, group_means=[dict(pair=i, **{x: a, y: b}) for i, (a, b) in enumerate(zip(xs, ys))],
                status=status)


def report(manifest_path, comparisons, out_path, extra=None):
    task, groups = load(manifest_path, expect_passes=(extra or {}).get('passes', 232), reps=(extra or {}).get('reps', 30))
    arms = sorted({a for (_, a) in groups})
    out = dict(manifest=str(manifest_path), manifest_sha256=K.sha(manifest_path),
               arms=arms, all_samples_retained=True,
               groups_per_arm={a: sum(1 for (p, aa) in groups if aa == a) for a in arms},
               methods='warm1/reps30/feedback; per-process-group mean; paired group differences; two-sided t 95% on df=P-1; no trimming, no rerun.',
               comparisons=[], extra=extra or {})
    for c in comparisons:
        out['comparisons'].append(compare(groups, c['arms'], c.get('labels', {})))
    if out_path:
        K.write_json(out_path, out)
    return out


if __name__ == '__main__':
    spec = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
    out = report(spec['manifest'], spec['comparisons'], spec.get('out'), spec.get('extra'))
    print(json.dumps({k: v for k, v in out.items() if k != 'comparisons'}, indent=2))
    for c in out['comparisons']:
        print(json.dumps({k: v for k, v in c.items() if k != 'group_means'}, indent=2))
