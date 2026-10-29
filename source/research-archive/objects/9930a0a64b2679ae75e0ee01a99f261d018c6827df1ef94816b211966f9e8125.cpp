#include "gtpin_api.h"
#include "gtpin_tool_utils.h"
#include <iostream>
using namespace gtpin;
class Inspect:public GtTool{public:
const char* Name()const override{return "inspectready";}
void OnKernelBuild(IGtKernelInstrument& i)override{
if(i.Kernel().HashId()!=0x0f0860f340d97767ULL)return;
for(auto b:i.Cfg().Bbls())for(auto op:b->Instructions()){
auto pc=i.Cfg().GetInstructionOffset(*op);
if((pc>=0x1740&&pc<=0x1790)||(pc>=0x6620&&pc<=0x6680)){
auto gd=op->GetGedIns();GED_RETURN_VALUE rv;auto imm=GED_GetImm(&gd,&rv);
std::cout<<"SYNC_API pc="<<std::hex<<pc<<std::dec<<" sync="<<op->IsSync()<<" nsrc="<<op->NumSources()<<" gedImm="<<std::hex<<imm<<std::dec<<" rv="<<rv<<" text="<<op->ToString().Get()<<std::endl;
for(uint32_t n=0;n<op->NumSources();n++){std::cout<<"SRC "<<n<<" isImm="<<op->SrcRegFile(n).IsImm()<<std::endl;}
}}}
void OnKernelRun(IGtKernelDispatch& d)override{d.SetProfilingMode(false);}
void OnKernelComplete(IGtKernelDispatch&)override{}
};
EXPORT_C_FUNC void GTPin_Entry(int argc,const char* argv[]){ConfigureGTPin(argc,argv);static Inspect t;t.Register();}
