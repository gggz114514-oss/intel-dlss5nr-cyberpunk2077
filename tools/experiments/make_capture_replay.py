"""Build an independent-frame replay plan; never substitutes FP16 history in a sequence run."""
import argparse
import hashlib
import json
from pathlib import Path
import shlex

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def build(plan, capture, output):
    meta = json.loads(capture.read_text(encoding='utf-8'))
    if meta['schema'] != 1 or sha(plan) != meta['source_plan_sha256']:
        raise ValueError('capture/source plan identity mismatch')
    push = meta['first_push']
    if len(push) != 32 or any(type(v) is not int or not 0 <= v <= 0xffffffff for v in push):
        raise ValueError('actual PUSH must contain 32 uint32 words')
    if push[22] != meta['noise_seed'] or push[23] & 4:
        raise ValueError('captured first PUSH disagrees with bridge noise/reset contract')
    snapshots = {v['resource']:v for v in meta['buffers']}
    if len(snapshots) != len(meta['buffers']) or len(snapshots) != 2:
        raise ValueError('expected two distinct pre/post snapshots')
    for item in list(snapshots.values())+[meta['output']]:
        path = capture.parent / item['file']
        if path.stat().st_size != item['bytes'] or sha(path) != item['sha256']:
            raise ValueError(f'snapshot identity mismatch: {path}')
    def absolute_asset(value):
        raw=value.strip('"')
        if raw == '-': return '"-"'
        path=Path(raw)
        return '"'+(path if path.is_absolute() else plan.parent/path).resolve().as_posix()+'"'
    lines = plan.read_text(encoding='utf-8-sig').splitlines()
    result=[]; ordinal=-1; buffer_id=-1; replaced=set(); push_done=False; output_seen=False
    # Preserve quoted names and Windows backslashes while relocating assets.
    for line in lines:
        kind = line.split(maxsplit=1)[0] if line.strip() else ''
        if kind == 'HISTORY':
            continue
        if kind == 'OUTPUT':
            fields=line.split()
            if int(fields[1]) == meta['output']['resource']:
                result.append(f'OUTPUT {fields[1]} {fields[2]} "replayed-network.bin"')
                output_seen=True
            continue
        if kind == 'BUFFER':
            buffer_id += 1
            if buffer_id in snapshots:
                fields=shlex.split(line,posix=False)
                item=snapshots[buffer_id]
                if int(fields[2]) != item['bytes']:
                    raise ValueError('snapshot/plan buffer size mismatch')
                path=(capture.parent/item['file']).resolve().as_posix()
                result.append(f'BUFFER {fields[1]} {fields[2]} "{path}"')
                replaced.add(buffer_id)
                continue
            fields=shlex.split(line,posix=False)
            fields[3]=absolute_asset(fields[3])
            line=' '.join(fields)
        if kind == 'PASS':
            ordinal += 1
            fields=shlex.split(line,posix=False)
            fields[3]=absolute_asset(fields[3])
            line=' '.join(fields)
        if kind == 'PUSH' and ordinal == 0:
            result.append('PUSH '+' '.join(map(str,push)))
            push_done=True
            continue
        result.append(line)
    if replaced != set(snapshots) or not push_done or not output_seen:
        raise ValueError('snapshot binding/PUSH/output not found in plan')
    header=result[0].split()
    header[4]='1'
    result[0]=' '.join(header)
    # Refuse overwriting an existing experiment identity.
    with output.open('x',encoding='utf-8',newline='\n') as f:
        f.write('\n'.join(result)+'\n')
    receipt={'mode':'INDEPENDENT_CAPTURED_HISTORY_FRAME', 'source_plan_sha256':sha(plan),
             'capture_metadata_sha256':sha(capture), 'replay_plan_sha256':sha(output),
             'expected_output_sha256':meta['output']['sha256'],
             'warning':'Not a continuous-feedback acceptance run; no GPU execution performed by this tool.'}
    output.with_suffix('.receipt.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    return receipt

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('plan',type=Path);ap.add_argument('capture',type=Path);ap.add_argument('output',type=Path)
    args=ap.parse_args()
    print(json.dumps(build(args.plan,args.capture,args.output),indent=2))
