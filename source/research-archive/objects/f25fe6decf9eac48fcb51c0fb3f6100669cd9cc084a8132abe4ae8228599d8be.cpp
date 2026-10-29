#include "gtpin_api.h"
#include <iostream>
#include <iomanip>
#include <mutex>
#include "gtpin_tool_utils.h"
using namespace gtpin;
class NativeMap final : public GtTool {
public:
    const char* Name() const override { return "nativemap"; }
    void OnKernelBuild(IGtKernelInstrument&) override {}
    void OnKernelRun(IGtKernelDispatch& dispatch) override {
        static std::mutex mutex; static unsigned sequence=0;
        std::lock_guard<std::mutex> guard(mutex);
        std::cout << "NATIVE_MAP " << sequence++ << " " << std::hex << std::setw(16) << std::setfill('0') << dispatch.Kernel().HashId() << std::dec << std::endl;
        dispatch.SetProfilingMode(false);
    }
    void OnKernelComplete(IGtKernelDispatch&) override {}
};
EXPORT_C_FUNC void GTPin_Entry(int argc,const char* argv[]) {
    ConfigureGTPin(argc,argv);
    static NativeMap tool;
    tool.Register();
}
