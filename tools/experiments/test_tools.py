"""CPU-only checks; no game or GPU execution."""
import hashlib,json,tempfile,unittest
from pathlib import Path
import numpy as np
from compare_frames import compare
from analyze_timing import compare as timing_compare
from make_capture_replay import build

class Tools(unittest.TestCase):
    def test_color_bias(self):
        with tempfile.TemporaryDirectory() as td:
            a=Path(td)/'a.bin';b=Path(td)/'b.bin'
            x=np.zeros((2,8,8,4),dtype='<f4');x.tofile(a);x[0,:,:,2]=.125;x.tofile(b)
            result=compare(a,b,x.shape,0,1)
            self.assertFalse(result['bit_equal']);self.assertEqual(result['mean_error_rgb'],[0,0,.125])
            self.assertEqual(result['mean_blue_minus_red_error'],.125)
            self.assertTrue(compare(a,a,x.shape,0,1)['bit_equal'])
    def test_paired_groups(self):
        groups={}
        for i,d in enumerate([.1,.2,.3]):
            groups[i,'base']=[dict(ok=True,mean_ms=10)]
            groups[i,'cand']=[dict(ok=True,mean_ms=10-d)]
        result=timing_compare(groups,('base','cand'),{})
        self.assertAlmostEqual(result['saving_ms'],.2)
        self.assertEqual(result['status'],'INDISTINCT')
        groups[0,'cand'][0]['ok']=False
        self.assertEqual(timing_compare(groups,('base','cand'),{})['status'],'GATE_FAILED')
    def test_replay_identity(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td);plan=root/'plan.txt';cap=root/'capture.json';out=root/'replay.txt'
            push=[0]*32;push[22]=42
            plan.write_text('PORT_NETWORK_1 1 2 1 1\nBUFFER pre 16 ""\nBUFFER post 16 ""\nPASS 0 "x" "../assets/test.spv" 32 0 0 32 1 1 1\nPUSH '+' '.join(map(str,push))+'\nOUTPUT 1 f32 "old.bin"\nHISTORY 0 1\n')
            entries=[]
            for i in range(2):
                data=bytes([i])*16;name=f'{i}.bin';(root/name).write_bytes(data)
                entries.append(dict(resource=i,file=name,bytes=16,sha256=hashlib.sha256(data).hexdigest()))
            meta=dict(schema=1,source_plan_sha256=hashlib.sha256(plan.read_bytes()).hexdigest(),first_push=push,noise_seed=42,buffers=entries,output=entries[1])
            cap.write_text(json.dumps(meta));build(plan,cap,out)
            self.assertNotIn('HISTORY',out.read_text());self.assertIn('replayed-network.bin',out.read_text());self.assertIn((root.parent/'assets/test.spv').as_posix(),out.read_text())
            meta['noise_seed']=43;cap.write_text(json.dumps(meta))
            with self.assertRaises(ValueError):build(plan,cap,root/'bad.txt')

if __name__=='__main__':unittest.main()
