// Actual T5 core on owned Vulkan images. This is a neural mini-frame test,
// separately scoped from D3D12 external sharing and the WB game component.
#include "port_network_bridge_backend.cpp"
#include <iostream>
int main(int argc,char** argv) {
    if(argc!=4)return 2;
    std::filesystem::path out(argv[2]);if(!std::filesystem::create_directory(out))return 2;
    std::string stage="START";
    auto mark=[&](const char* s){stage=s;std::ofstream(out/"checkpoint.txt")<<stage<<"\n";std::cout<<stage<<std::endl;};
    try {
        mark("DEVICE_CREATE");HMODULE loader=LoadLibraryA("vulkan-1.dll");if(!loader)throw std::runtime_error("Vulkan loader");
        auto gipa=reinterpret_cast<PFN_vkGetInstanceProcAddr>(GetProcAddress(loader,"vkGetInstanceProcAddr"));
        auto create=reinterpret_cast<PFN_vkCreateInstance>(gipa(VK_NULL_HANDLE,"vkCreateInstance"));
        VkApplicationInfo app{VK_STRUCTURE_TYPE_APPLICATION_INFO};app.apiVersion=VK_API_VERSION_1_3;app.pApplicationName="T5_actual_owned_image_mini_frame";
        VkInstanceCreateInfo ici{VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};ici.pApplicationInfo=&app;VkInstance instance;CHECK(create(&ici,nullptr,&instance));
#define IFN(f) auto f=reinterpret_cast<PFN_##f>(gipa(instance,#f));if(!f)throw std::runtime_error("missing " #f)
        IFN(vkDestroyInstance);IFN(vkEnumeratePhysicalDevices);IFN(vkGetPhysicalDeviceProperties2);IFN(vkGetPhysicalDeviceQueueFamilyProperties);IFN(vkCreateDevice);IFN(vkGetDeviceProcAddr);
        uint32_t n=0;CHECK(vkEnumeratePhysicalDevices(instance,&n,nullptr));std::vector<VkPhysicalDevice> devices(n);CHECK(vkEnumeratePhysicalDevices(instance,&n,devices.data()));VkPhysicalDevice phy=VK_NULL_HANDLE;VkPhysicalDeviceProperties props{};
        for(auto p:devices){VkPhysicalDeviceProperties2 r{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2};vkGetPhysicalDeviceProperties2(p,&r);if(r.properties.vendorID==0x8086&&r.properties.deviceID==0xe20b){phy=p;props=r.properties;}}
        if(!phy)throw std::runtime_error("B580 missing");vkGetPhysicalDeviceQueueFamilyProperties(phy,&n,nullptr);std::vector<VkQueueFamilyProperties> queues(n);vkGetPhysicalDeviceQueueFamilyProperties(phy,&n,queues.data());uint32_t family=0;while(family<n&&!(queues[family].queueFlags&VK_QUEUE_COMPUTE_BIT))++family;
        VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};cm.cooperativeMatrix=VK_TRUE;
        VkPhysicalDeviceShaderFloat16Int8Features half{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES};half.shaderFloat16=VK_TRUE;
        VkPhysicalDevice16BitStorageFeatures storage{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES};storage.storageBuffer16BitAccess=VK_TRUE;
        VkPhysicalDeviceSubgroupSizeControlFeatures sg{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_FEATURES};sg.subgroupSizeControl=VK_TRUE;sg.computeFullSubgroups=VK_TRUE;
        VkPhysicalDeviceSynchronization2Features sync{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES};sync.synchronization2=VK_TRUE;
        VkPhysicalDeviceVulkanMemoryModelFeatures mm{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES};mm.vulkanMemoryModel=VK_TRUE;
        cm.pNext=&half;half.pNext=&storage;storage.pNext=&sg;sg.pNext=&sync;sync.pNext=&mm;
        float priority=1;VkDeviceQueueCreateInfo qi{VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO};qi.queueFamilyIndex=family;qi.queueCount=1;qi.pQueuePriorities=&priority;
        const char* extension="VK_KHR_cooperative_matrix";VkDeviceCreateInfo di{VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO};di.pNext=&cm;di.queueCreateInfoCount=1;di.pQueueCreateInfos=&qi;di.enabledExtensionCount=1;di.ppEnabledExtensionNames=&extension;VkDevice device;CHECK(vkCreateDevice(phy,&di,nullptr,&device));
#define DFN(f) auto f=reinterpret_cast<PFN_##f>(vkGetDeviceProcAddr(device,#f));if(!f)throw std::runtime_error("missing " #f)
        DFN(vkGetDeviceQueue);DFN(vkDestroyDevice);DFN(vkCreateImage);DFN(vkDestroyImage);DFN(vkGetImageMemoryRequirements2);DFN(vkBindImageMemory);DFN(vkCreateImageView);DFN(vkDestroyImageView);
        DFN(vkCmdCopyBufferToImage);DFN(vkCmdCopyImageToBuffer);DFN(vkCreateQueryPool);DFN(vkDestroyQueryPool);DFN(vkCmdResetQueryPool);DFN(vkCmdWriteTimestamp2);DFN(vkGetQueryPoolResults);
        VkQueue queue;vkGetDeviceQueue(device,family,0,&queue);NRVK_Config cfg{};cfg.abi_size=sizeof(cfg);cfg.manifest_dir=argv[1];NRVK_Backend* b=nullptr;
        mark("ACTUAL_BACKEND_INIT");int rc=nrvk_backend_init(instance,device,phy,queue,family,&cfg,&b);if(rc)throw std::runtime_error(port_network_bridge_backend_last_error());
        if(std::string(argv[3])=="capture"){
            auto root=std::filesystem::absolute(out/"snapshots");std::filesystem::create_directory(root);
            auto control=std::filesystem::absolute(out/"capture-control");std::filesystem::create_directory(control);b->manifest_dir=control.string();
            std::ofstream(control/"capture-plan-sha256.txt")<<"fa85e9f2e71146ce38654dbbd715baa7591c960208cee65bf7098e44fc148367";
            std::ofstream(control/"capture.request")<<root.string()<<"\n2\n";
        }else if(std::string(argv[3])!="control")throw std::runtime_error("mode must be control or capture");
        std::ofstream(out/"actual_pool.json")<<"{\"buffers\":502,\"native_rows\":152,\"network_dispatches\":232,\"pool_blocks\":"<<b->pool_memory.size()<<"}\n";
        auto input=read_bytes("@NR_WORKSPACE@/src/project/artifacts/parallel-port-20261013/io/block0/fixture-cold-v2/ioport_images.f32.bin");auto& pre=b->plan.passes.front().push;auto& post=b->plan.passes.back().push;
        const VkDeviceSize plane=14745600,pixels=1280*720,texture_bytes=pixels*8;
        struct Image{VkImage handle=VK_NULL_HANDLE;VkDeviceMemory memory=VK_NULL_HANDLE;VkImageView view=VK_NULL_HANDLE;VkFormat format;VkImageUsageFlags usage;};Image images[4];
        auto image=[&](Image& x,VkFormat format,VkImageUsageFlags usage){x.format=format;x.usage=usage;VkImageCreateInfo ci{VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};ci.imageType=VK_IMAGE_TYPE_2D;ci.format=format;ci.extent={1280,720,1};ci.mipLevels=ci.arrayLayers=1;ci.samples=VK_SAMPLE_COUNT_1_BIT;ci.tiling=VK_IMAGE_TILING_OPTIMAL;ci.usage=usage;ci.initialLayout=VK_IMAGE_LAYOUT_UNDEFINED;CHECK(vkCreateImage(device,&ci,nullptr,&x.handle));
            VkMemoryDedicatedRequirements dedicated{VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS};VkMemoryRequirements2 req{VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2};req.pNext=&dedicated;VkImageMemoryRequirementsInfo2 query{VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2};query.image=x.handle;vkGetImageMemoryRequirements2(device,&query,&req);uint32_t type=0;while(type<b->memory.memoryTypeCount&&!((req.memoryRequirements.memoryTypeBits&(1u<<type))&&(b->memory.memoryTypes[type].propertyFlags&VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)))++type;
            VkMemoryDedicatedAllocateInfo da{VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO};da.image=x.handle;VkMemoryAllocateInfo ai{VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};ai.pNext=dedicated.requiresDedicatedAllocation?&da:nullptr;ai.allocationSize=req.memoryRequirements.size;ai.memoryTypeIndex=type;CHECK(b->vkAllocateMemory(device,&ai,nullptr,&x.memory));CHECK(vkBindImageMemory(device,x.handle,x.memory,0));
            VkImageViewCreateInfo vi{VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO};vi.image=x.handle;vi.viewType=VK_IMAGE_VIEW_TYPE_2D;vi.format=format;vi.subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};CHECK(vkCreateImageView(device,&vi,nullptr,&x.view));};
        image(images[0],VK_FORMAT_R32G32B32A32_SFLOAT,VK_IMAGE_USAGE_SAMPLED_BIT|VK_IMAGE_USAGE_TRANSFER_DST_BIT);
        image(images[1],VK_FORMAT_R32G32_SFLOAT,VK_IMAGE_USAGE_SAMPLED_BIT|VK_IMAGE_USAGE_TRANSFER_DST_BIT);
        image(images[2],VK_FORMAT_R32_SFLOAT,VK_IMAGE_USAGE_SAMPLED_BIT|VK_IMAGE_USAGE_TRANSFER_DST_BIT);
        image(images[3],VK_FORMAT_R16G16B16A16_SFLOAT,VK_IMAGE_USAGE_STORAGE_BIT|VK_IMAGE_USAGE_TRANSFER_SRC_BIT);
        size_t body_index=0;for(auto& bind:b->plan.passes.back().bindings)if(bind.binding==2)body_index=bind.resource;
        VkDeviceSize body_bytes=b->plan.buffers[body_index].bytes;
        Buffer staging;staging.name="test_upload_readback";staging.bytes=plane*4+texture_bytes+body_bytes;make_buffer(b,staging,VK_BUFFER_USAGE_TRANSFER_SRC_BIT|VK_BUFFER_USAGE_TRANSFER_DST_BIT,VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT|VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);void* mapped;CHECK(b->vkMapMemory(device,staging.memory,0,VK_WHOLE_SIZE,0,&mapped));memcpy(mapped,input.data(),40550480);
        VkCommandPoolCreateInfo cp{VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};cp.flags=VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;cp.queueFamilyIndex=family;VkCommandPool pool;CHECK(b->vkCreateCommandPool(device,&cp,nullptr,&pool));VkCommandBufferAllocateInfo ca{VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};ca.commandPool=pool;ca.level=VK_COMMAND_BUFFER_LEVEL_PRIMARY;ca.commandBufferCount=1;VkCommandBuffer cb;CHECK(b->vkAllocateCommandBuffers(device,&ca,&cb));VkFenceCreateInfo fc{VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};VkFence fence;CHECK(b->vkCreateFence(device,&fc,nullptr,&fence));
        auto begin=[&](){CHECK(b->vkResetCommandBuffer(cb,0));VkCommandBufferBeginInfo bi{VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};bi.flags=VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;CHECK(b->vkBeginCommandBuffer(cb,&bi));};
        auto submit=[&](bool nn){CHECK(b->vkEndCommandBuffer(cb));CHECK(b->vkResetFences(device,1,&fence));VkSubmitInfo si{VK_STRUCTURE_TYPE_SUBMIT_INFO};si.commandBufferCount=1;si.pCommandBuffers=&cb;VkResult r=b->vkQueueSubmit(queue,1,&si,fence);if(nn)port_network_bridge_backend_submit_result(b,fence,r);CHECK(r);CHECK(b->vkWaitForFences(device,1,&fence,VK_TRUE,60ULL*1000*1000*1000));};
        auto image_dep=[&](Image& x,VkImageLayout old,VkImageLayout next,VkPipelineStageFlags src,VkPipelineStageFlags dst,VkAccessFlags a,VkAccessFlags z){VkImageMemoryBarrier m{VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};m.oldLayout=old;m.newLayout=next;m.srcAccessMask=a;m.dstAccessMask=z;m.srcQueueFamilyIndex=m.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED;m.image=x.handle;m.subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1};b->vkCmdPipelineBarrier(cb,src,dst,0,0,nullptr,0,nullptr,1,&m);};
        mark("REAL_IMAGES_UPLOAD");begin();
        const VkDeviceSize offsets[]={0,7372820ULL*4,9216020ULL*4};
        for(unsigned i=0;i<3;++i){image_dep(images[i],VK_IMAGE_LAYOUT_UNDEFINED,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,0,VK_ACCESS_TRANSFER_WRITE_BIT);VkBufferImageCopy copy{};copy.bufferOffset=offsets[i];copy.imageSubresource={VK_IMAGE_ASPECT_COLOR_BIT,0,0,1};copy.imageExtent={1280,720,1};vkCmdCopyBufferToImage(cb,staging.handle,images[i].handle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,1,&copy);image_dep(images[i],VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,VK_IMAGE_LAYOUT_GENERAL,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,VK_ACCESS_TRANSFER_WRITE_BIT,VK_ACCESS_SHADER_READ_BIT);}
        image_dep(images[3],VK_IMAGE_LAYOUT_UNDEFINED,VK_IMAGE_LAYOUT_GENERAL,VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,0,VK_ACCESS_SHADER_WRITE_BIT);submit(false);
        NRVK_FrameParams params{};params.abi_size=sizeof(params);params.render_width=params.output_width=1280;params.render_height=params.output_height=720;params.pre_exposure=params.exposure_scale=1;params.motion_scale_x=params.motion_scale_y=1;params.motion_scale_origin=NRB_MV_DLSS_NGX;
        VkImageView views[]={images[0].view,images[1].view,images[2].view,VK_NULL_HANDLE};PortNetworkBridgeFrameIO io{};io.v3={sizeof(io),4,views,images[3].view,&params};io.nrb_controls.abi_size=sizeof(NRB_Controls);io.nrb_controls.input_height=720;io.nrb_controls.enabled=1;io.noise_seed=1;
        memcpy(io.model_controls,input.data()+14745600,80);io.model_controls[7]=1;io.model_controls[8]=1;
        io.nrb_controls.model_intensity=params.model_intensity=1;
        {std::ofstream c(out/"controls_contract.json");c<<"{\"noise_seed\":1,\"frame_ids\":[0,1],\"control_epochs\":[0,0],\"reset_history\":[true,false],\"controls20\":[";for(unsigned i=0;i<20;++i)c<<(i?",":"")<<std::setprecision(10)<<io.model_controls[i];c<<"],\"profile\":\"native720 model-domain LDR, exposure1,HDR0,jitter0,native motion/depth; conditioning from frozen bundle; not an NRB UI mapping proof\"}\n";}
        for(unsigned i=0;i<4;++i){auto& m=io.images[i==3?4:i];m.image=images[i].handle;m.format=images[i].format;m.extent={1280,720};m.valid_rect={{0,0},{1280,720}};m.usage=images[i].usage;m.layout=VK_IMAGE_LAYOUT_GENERAL;m.queue_family=family;}
        VkQueryPoolCreateInfo qc{VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO};qc.queryType=VK_QUERY_TYPE_TIMESTAMP;qc.queryCount=2;VkQueryPool queries;CHECK(vkCreateQueryPool(device,&qc,nullptr,&queries));std::vector<double> times;
        auto save=[&](const std::string& file,VkDeviceSize offset,VkDeviceSize bytes){std::ofstream stream(out/file,std::ios::binary);stream.write(static_cast<const char*>(mapped)+offset,std::streamsize(bytes));if(!stream)throw std::runtime_error("readback write");};
        for(unsigned frame=0;frame<2;++frame){io.frame_id=frame;params.reset_history=frame==0?1:0;mark(frame==0?"REAL_FRAME_RESET":"REAL_FRAME_HISTORY");begin();vkCmdResetQueryPool(cb,queries,0,2);vkCmdWriteTimestamp2(cb,VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT,queries,0);
            rc=nrvk_backend_frame(b,cb,&io.v3);if(rc)throw std::runtime_error(port_network_bridge_backend_last_error());vkCmdWriteTimestamp2(cb,VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT,queries,1);
            barrier(b,cb,VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_ACCESS_SHADER_WRITE_BIT,VK_ACCESS_TRANSFER_READ_BIT);image_dep(images[3],VK_IMAGE_LAYOUT_GENERAL,VK_IMAGE_LAYOUT_GENERAL,VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_ACCESS_SHADER_WRITE_BIT,VK_ACCESS_TRANSFER_READ_BIT);
            VkBufferCopy tensor{0,0,plane*2};b->vkCmdCopyBuffer(cb,b->plan.buffers[b->output].handle,staging.handle,1,&tensor);
            VkBufferImageCopy imagecopy{};imagecopy.bufferOffset=plane*2;imagecopy.imageSubresource={VK_IMAGE_ASPECT_COLOR_BIT,0,0,1};imagecopy.imageExtent={1280,720,1};vkCmdCopyImageToBuffer(cb,images[3].handle,VK_IMAGE_LAYOUT_GENERAL,staging.handle,1,&imagecopy);
            VkBufferCopy source{0,plane*2+texture_bytes,plane};b->vkCmdCopyBuffer(cb,b->plan.buffers[b->pre].handle,staging.handle,1,&source);
            VkBufferCopy history{14745680,plane*3+texture_bytes,plane};b->vkCmdCopyBuffer(cb,b->plan.buffers[b->post].handle,staging.handle,1,&history);
            VkBufferCopy body{0,plane*4+texture_bytes,body_bytes};b->vkCmdCopyBuffer(cb,b->plan.buffers[body_index].handle,staging.handle,1,&body);
            barrier(b,cb,VK_PIPELINE_STAGE_TRANSFER_BIT,VK_PIPELINE_STAGE_HOST_BIT,VK_ACCESS_TRANSFER_WRITE_BIT,VK_ACCESS_HOST_READ_BIT);submit(true);
            uint64_t stamp[2];CHECK(vkGetQueryPoolResults(device,queries,0,2,sizeof(stamp),stamp,8,VK_QUERY_RESULT_64_BIT));uint32_t bits=queues[family].timestampValidBits;uint64_t mask=bits==64?UINT64_MAX:((uint64_t(1)<<bits)-1);times.push_back(double((stamp[1]-stamp[0])&mask)*props.limits.timestampPeriod/1e6);
            save("frame"+std::to_string(frame)+"_fp32.bin",0,plane*2);save("frame"+std::to_string(frame)+"_out_fp16.bin",plane*2,texture_bytes);save("frame"+std::to_string(frame)+"_gather_color.bin",plane*2+texture_bytes,plane);save("frame"+std::to_string(frame)+"_input_history.bin",plane*3+texture_bytes,plane);save("frame"+std::to_string(frame)+"_body_fp16.bin",plane*4+texture_bytes,body_bytes);
        }
        mark("RELEASE");CHECK(b->vkQueueWaitIdle(queue));vkDestroyQueryPool(device,queries,nullptr);
        b->vkUnmapMemory(device,staging.memory);b->vkDestroyBuffer(device,staging.handle,nullptr);b->vkFreeMemory(device,staging.memory,nullptr);b->vkDestroyFence(device,fence,nullptr);b->vkDestroyCommandPool(device,pool,nullptr);
        for(auto& x:images){vkDestroyImageView(device,x.view,nullptr);vkDestroyImage(device,x.handle,nullptr);b->vkFreeMemory(device,x.memory,nullptr);}nrvk_backend_release(b);vkDestroyDevice(device,nullptr);vkDestroyInstance(instance,nullptr);FreeLibrary(loader);
        std::ofstream(out/"receipt.json")<<std::setprecision(10)<<"{\"status\":\"GPU_EXECUTED_COMPARE_PENDING\",\"normal_close\":true,\"native_rows\":152,\"network_dispatches\":232,\"bridge_dispatches\":2,\"frames\":2,\"noise_seed\":1,\"reset_then_history\":true,\"intensity\":1,\"frame_gpu_ms\":["<<times[0]<<","<<times[1]<<"],\"timestamp_scope\":\"gather+actualnetwork+scatter+barriers; init/upload/readback excluded; semantic2-frame ticket, not stable performance benchmark\",\"D3D12_external_interop_tested\":false,\"WB_component_tested\":false}\n";
        mark("NORMAL_CLOSE");return 0;
    }catch(const std::exception& e){std::ofstream(out/"failure.txt")<<stage<<": "<<e.what()<<"\n";std::cerr<<stage<<": "<<e.what()<<std::endl;return 1;}
}
