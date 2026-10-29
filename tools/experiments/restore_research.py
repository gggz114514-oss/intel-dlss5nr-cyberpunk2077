"""Restore archived research text to a NEW workspace, expanding local path tokens."""
from pathlib import Path
import argparse,json,hashlib
ROOT=Path(__file__).resolve().parents[2]/'source/research-archive'
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out',type=Path,required=True);p.add_argument('--paths',type=Path,required=True)
    a=p.parse_args();dest=a.out.resolve()
    if dest.exists():p.error('Output must be a new directory')
    mapping=json.loads(a.paths.read_text(encoding='utf-8-sig'))
    index=json.loads((ROOT/'INDEX.json').read_text(encoding='utf-8'))
    if set(mapping)!=set(index['placeholder_names']):p.error('Path map must define every placeholder from INDEX.json')
    dest.mkdir(parents=True)
    for item in index['files']:
        data=(ROOT/item['archive_path']).read_bytes()
        if hashlib.sha256(data).hexdigest()!=item['published_sha256']:raise ValueError('Archive integrity mismatch')
        target=(dest/item['original_relative_path']).resolve()
        if not target.is_relative_to(dest):raise ValueError('Path outside destination')
        text=data.decode('utf-8')
        for token,value in mapping.items():text=text.replace(token,str(value).replace(chr(92),'/'))
        target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text,encoding='utf-8')
    print('Restored',len(index['files']),'text files. Historical scripts require their recorded data/tool dependencies; no script was executed.')
