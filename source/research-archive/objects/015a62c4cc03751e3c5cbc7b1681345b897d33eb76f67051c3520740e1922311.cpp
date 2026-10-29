#define VK_NO_PROTOTYPES
#include <windows.h>
#include <vulkan/vulkan.h>
#include <cstdio>
#include <vector>

int main() {
    auto dll = LoadLibraryW(L"vulkan-1.dll");
    if (!dll) return 1;
    auto get = reinterpret_cast<PFN_vkGetInstanceProcAddr>(GetProcAddress(dll,"vkGetInstanceProcAddr"));
    if (!get) return 2;
    auto create = reinterpret_cast<PFN_vkCreateInstance>(get(nullptr,"vkCreateInstance"));
    VkApplicationInfo app{VK_STRUCTURE_TYPE_APPLICATION_INFO}; app.apiVersion=VK_API_VERSION_1_3;
    VkInstanceCreateInfo ci{VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO}; ci.pApplicationInfo=&app;
    VkInstance instance{};
    VkResult result=create(&ci,nullptr,&instance);
    if(result!=VK_SUCCESS) { std::printf("create_instance=%d\n",result); return 3; }
    auto enumerate=reinterpret_cast<PFN_vkEnumeratePhysicalDevices>(get(instance,"vkEnumeratePhysicalDevices"));
    auto properties=reinterpret_cast<PFN_vkGetPhysicalDeviceProperties>(get(instance,"vkGetPhysicalDeviceProperties"));
    auto features=reinterpret_cast<PFN_vkGetPhysicalDeviceFeatures2>(get(instance,"vkGetPhysicalDeviceFeatures2"));
    auto destroy=reinterpret_cast<PFN_vkDestroyInstance>(get(instance,"vkDestroyInstance"));
    uint32_t count=0; result=enumerate(instance,&count,nullptr);
    if(result!=VK_SUCCESS) { destroy(instance,nullptr);return 4; }
    std::vector<VkPhysicalDevice> devices(count); result=enumerate(instance,&count,devices.data());
    if(result!=VK_SUCCESS) { destroy(instance,nullptr);return 5; }
    for(auto device:devices) {
        VkPhysicalDeviceProperties p{}; properties(device,&p);
        VkPhysicalDeviceShaderClockFeaturesKHR clock{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_CLOCK_FEATURES_KHR};
        VkPhysicalDeviceFeatures2 f{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2}; f.pNext=&clock; features(device,&f);
        std::printf("device=%s vendor=%u driver=%u subgroup_clock=%u device_clock=%u timestamp_period_ns=%.9g\n",p.deviceName,p.vendorID,p.driverVersion,clock.shaderSubgroupClock,clock.shaderDeviceClock,p.limits.timestampPeriod);
    }
    destroy(instance,nullptr);
    return 0;
}
