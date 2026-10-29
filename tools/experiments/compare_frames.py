"""Compare matching raw NR outputs, including channel bias and spatial error."""
import argparse, hashlib, json
from pathlib import Path
import numpy as np

def compare(reference, candidate, shape, view, peak):
    a=np.fromfile(reference,dtype='<f4').reshape(shape)[view,:,:,:3].astype(np.float64)
    b=np.fromfile(candidate,dtype='<f4').reshape(shape)[view,:,:,:3].astype(np.float64)
    if not np.isfinite(a).all() or not np.isfinite(b).all():
        raise ValueError('Nonfinite image values')
    e=b-a; mse=float(np.mean(e*e)); rgb=e.mean(axis=(0,1))
    tiles=[]
    for iy,ys in enumerate(np.array_split(np.arange(a.shape[0]),4)):
        for ix,xs in enumerate(np.array_split(np.arange(a.shape[1]),4)):
            z=e[np.ix_(ys,xs)]
            tiles.append(dict(tile=[iy,ix],bias_rgb=z.mean(axis=(0,1)).tolist(),mae=float(abs(z).mean())))
    return dict(reference_sha256=hashlib.sha256(Path(reference).read_bytes()).hexdigest(),
                candidate_sha256=hashlib.sha256(Path(candidate).read_bytes()).hexdigest(),
                bit_equal=Path(reference).read_bytes()==Path(candidate).read_bytes(),
                view=view,peak=peak,rmse=mse**.5,psnr_db=None if mse==0 else float(10*np.log10(peak*peak/mse)),
                mean_error_rgb=rgb.tolist(),mean_blue_minus_red_error=float(rgb[2]-rgb[0]),
                mae_rgb=abs(e).mean(axis=(0,1)).tolist(),max_abs=float(abs(e).max()),
                abs_error_p99=float(np.quantile(abs(e),.99)),tiles=tiles)

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('reference',type=Path);p.add_argument('candidate',type=Path)
    p.add_argument('--shape',type=int,nargs=4,default=[2,720,1280,4])
    p.add_argument('--view',type=int,default=0);p.add_argument('--peak',type=float,default=1)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    if a.peak<=0 or not 0<=a.view<a.shape[0]:p.error('positive peak and valid view required')
    result=compare(a.reference,a.candidate,a.shape,a.view,a.peak)
    a.out.write_text(json.dumps(result,indent=2,allow_nan=False)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='tiles'},indent=2))
