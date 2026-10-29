"""Create a local SHA256 inventory for data to back up privately; uploads nothing."""
from pathlib import Path
import argparse,hashlib,json
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--root',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
    a=p.parse_args();root=a.root.resolve();out=a.out.resolve()
    if out.is_relative_to(root):p.error('Keep the inventory outside the inventoried tree')
    files=[]
    for path in sorted(root.rglob('*')):
        if path.is_file():
            h=hashlib.sha256()
            with path.open('rb') as f:
                for chunk in iter(lambda:f.read(8*1024*1024),b''):h.update(chunk)
            files.append(dict(path=path.relative_to(root).as_posix(),bytes=path.stat().st_size,sha256=h.hexdigest()))
    out.write_text(json.dumps(dict(files=files,total_bytes=sum(x['bytes'] for x in files)),indent=2)+'\n',encoding='utf-8')
    print(len(files),'files; inventory only, no backup/upload performed')
