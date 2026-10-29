#include "gtpin_api.h"
#include "gtpin_tool_utils.h"
using namespace gtpin;
class NativeOnly final : public GtTool {
public:
    const char* Name() const override { return "nativeonly"; }
    void OnKernelBuild(IGtKernelInstrument&) override {}
    void OnKernelRun(IGtKernelDispatch& dispatch) override { dispatch.SetProfilingMode(false); }
    void OnKernelComplete(IGtKernelDispatch&) override {}
};
EXPORT_C_FUNC void GTPin_Entry(int argc,const char* argv[]) {
    ConfigureGTPin(argc,argv);
    static NativeOnly tool;
    tool.Register();
}
