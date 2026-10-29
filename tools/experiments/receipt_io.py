from pathlib import Path
import hashlib, json

def read_json(p):
    return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def write_json(p, obj):
    Path(p).write_text(json.dumps(obj, indent=2)+'\n', encoding='utf-8')
def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()
