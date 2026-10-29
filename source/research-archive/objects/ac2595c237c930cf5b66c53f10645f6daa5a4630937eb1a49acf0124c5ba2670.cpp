#include "gtpin_api.h"
#include "gtpin_tool_utils.h"
#include <map>
#include <iostream>
using namespace gtpin;
Knob<bool> split("split",false,"Split K/V readiness; default clones original group");
Knob<bool> execute("execute_modified",false,"Execute instrumented code only after main native review");
struct Site {uint32_t wait,k0,k1,v0,last,all,kmask,vmask;};
static Site sites[]={{0x1750,0x1760,0x1770,0x1780,0x1780,0xb80,0x180,0xa00},{0x6630,0x6640,0x6650,0x6660,0x6670,0xd80,0x180,0xc00}};
class Split final:public GtTool {
public:
 const char* Name() const override{return "kvready";}
 void OnKernelBuild(IGtKernelInstrument& inst) override {
  if(inst.Kernel().HashId()!=0x0f0860f340d97767ULL)return;
  std::map<uint32_t,const IGtIns*> ins;
  for(auto b:inst.Cfg().Bbls())for(auto i:b->Instructions())ins[inst.Cfg().GetInstructionOffset(*i)]=i;
  auto& f=inst.Coder().InstructionFactory();
  for(auto s:sites){
   const auto* w=ins.at(s.wait);
   GTPIN_ASSERT_MSG(w->IsSync() && w->NumSources()==2 && w->SrcRegFile(0).IsImm(),"expected allwr immediate");
   GTPIN_ASSERT_MSG(w->SrcImmOperand(0).Value()==s.all,"allwr mask differs");
   GtGenProcedure p;
   auto& kw=f.Make(*w);if(split)kw.SetSrcImmOperand(0,GtImmU32(s.kmask));p+=kw;
   for(uint32_t pc=s.k0;pc<=s.last;pc+=16){
    if(split && pc==s.v0){auto& vw=f.Make(*w);vw.SetSrcImmOperand(0,GtImmU32(s.vmask));p+=vw;}
    auto& op=f.Make(*ins.at(pc));if(split && pc==s.k1)op.SetThreadCtrl(GED_THREAD_CTRL_Normal);p+=op;
   }
   GTPIN_ASSERT(inst.InstrumentInstruction(*w,GtIpoint::Before(),p));
   GTPIN_ASSERT(inst.RemoveInstruction(*w));
   for(uint32_t pc=s.k0;pc<=s.last;pc+=16)GTPIN_ASSERT(inst.RemoveInstruction(*ins.at(pc)));
   std::cout<<"KVREADY_SITE "<<std::hex<<s.wait<<" split="<<split.GetValue()<<" dry="<<!execute.GetValue()<<std::dec<<std::endl;
  }
 }
 void OnKernelRun(IGtKernelDispatch& d) override {bool on=execute.GetValue()&&d.Kernel().HashId()==0x0f0860f340d97767ULL&&d.Kernel().IsInstrumented();d.SetProfilingMode(on);std::cout<<"KVREADY_RUN "<<std::hex<<d.Kernel().HashId()<<std::dec<<" modified="<<on<<std::endl;}
 void OnKernelComplete(IGtKernelDispatch&) override{}
};
EXPORT_C_FUNC void GTPin_Entry(int argc,const char* argv[]){ConfigureGTPin(argc,argv);static Split tool;tool.Register();}
