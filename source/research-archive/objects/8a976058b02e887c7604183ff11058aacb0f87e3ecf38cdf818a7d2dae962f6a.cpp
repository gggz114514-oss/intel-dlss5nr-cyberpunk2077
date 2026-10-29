#include "port_network_bridge_backend.cpp"
#include <iostream>
static std::vector<VkBufferCopy> recorded;
static void VKAPI_CALL copy_spy(VkCommandBuffer,VkBuffer,VkBuffer,uint32_t n,const VkBufferCopy* c){for(uint32_t i=0;i<n;++i)recorded.push_back(c[i]);}
static void VKAPI_CALL barrier_spy(VkCommandBuffer,VkPipelineStageFlags,VkPipelineStageFlags,VkDependencyFlags,uint32_t,const VkMemoryBarrier*,uint32_t,const VkBufferMemoryBarrier*,uint32_t,const VkImageMemoryBarrier*){}
int main(int argc,char** argv){try{
    if(argc!=2)throw std::runtime_error("output directory required");
    NRVK_Backend b; b.capture_root=argv[1];
    if(!std::filesystem::create_directory(b.capture_root))throw std::runtime_error("test output already exists");
    b.manifest_dir=b.capture_root.string();
    {std::ofstream f(b.capture_root/"capture-plan-sha256.txt");f<<std::string(64,'a');}
    b.plan.buffers.resize(3);b.pre=0;b.post=1;b.output=2;
    for(unsigned i=0;i<3;++i){b.plan.buffers[i].bytes=4;b.plan.buffers[i].handle=(VkBuffer)(uintptr_t)(i+1);}
    unsigned char payload[12]={1,2,3,4,5,6,7,8,9,10,11,12};b.capture_map=payload;
    {std::ofstream f(b.capture_root/"capture.request");f<<b.capture_root.string()<<"\n2\n";}
    capture_prepare(&b);
    if(b.capture_left!=2||std::filesystem::exists(b.capture_root/"capture.request"))throw std::runtime_error("request consumed with handle closed");
    b.capture_push.resize(32);b.capture_push[22]=17;b.capture_frame=4;b.capture_epoch=2;
    b.vkCmdCopyBuffer=copy_spy;b.vkCmdPipelineBarrier=barrier_spy;
    capture_copy(&b,(VkCommandBuffer)1,false);capture_copy(&b,(VkCommandBuffer)1,true);
    if(recorded.size()!=3||recorded[0].dstOffset!=0||recorded[1].dstOffset!=4||recorded[2].dstOffset!=8)throw std::runtime_error("copy offsets");
    b.capture_pending=true;capture_flush(&b);
    if(std::filesystem::exists(b.capture_root/"2-4"))throw std::runtime_error("unsubmitted capture written");
    b.capture_submitted=true;capture_flush(&b);
    if(b.capture_pending||b.capture_submitted)throw std::runtime_error("capture not retired");
    auto bytes=read_bytes((b.capture_root/"2-4/post.bin").string());
    if(bytes.size()!=4||memcmp(bytes.data(),payload+4,4))throw std::runtime_error("captured payload");
    if(!std::filesystem::exists(b.capture_root/"2-4/capture.json"))throw std::runtime_error("metadata missing");
    std::cout<<"CAPTURE_CPU_PASS copy offsets, submit gating, payload and metadata; no GPU validation\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
