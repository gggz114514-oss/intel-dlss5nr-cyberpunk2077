/*========================== begin_copyright_notice ============================
Copyright (C) 2015-2026 Intel Corporation

SPDX-License-Identifier: MIT
============================= end_copyright_notice ===========================*/

/*!
 * @file Implementation of the Funtime tool
 */

#include <fstream>
#include <sstream>
#include <iomanip>
#include <algorithm>

#include "funtime.h"
#include "gt_knob.h"

using namespace gtpin;
using namespace std;

/* ============================================================================================= */
// Configuration
/* ============================================================================================= */
Knob<int> knobStartPC("start_pc", 0, "Original ISA start PC in decimal, inclusive before instruction");
Knob<int> knobEndPC("end_pc", -1, "Original ISA end PC in decimal, exclusive before instruction; -1=EOT");
Knob<bool> knobClockOnly("clock_only", false, "No timing: same live scalar filled with constants, same exit writes");
Knob<bool> knobImmediateReport("immediate_report", false, "Perturbation control: report at endpoint instead of exit");
Knob<int>  knobNumThreadBuckets("num_thread_buckets", 32, "Number of thread buckets. Default - 32, zero - maximum thread buckets");
Knob<bool> knobPerTileProfiling("per_tile_profiling", false, "Enable per-tile (subdevice) profiling");
Knob<bool> knobSkipZeroResults("skip_zero_results", false, "Skip zero results in the Funtime output");

/* ============================================================================================= */
// Funtime implementation
/* ============================================================================================= */
Funtime* Funtime::Instance()
{
    static Funtime instance;
    return &instance;
}

void Funtime::OnKernelBuild(IGtKernelInstrument& instrumentor)
{
    const IGtKernel&            kernel          = instrumentor.Kernel();
    const IGtCfg&               cfg             = instrumentor.Cfg();
    const IGtGenCoder&          coder           = instrumentor.Coder();
    const IGtGenArch&           genArch         = GTPin_GetCore()->GenArch();
    const IGtGenModel&          genModel        = kernel.GenModel();
    IGtProfileBufferAllocator&  allocator       = instrumentor.ProfileBufferAllocator();
    IGtVregFactory&             vregs           = coder.VregFactory();
    bool                        is64BitCounter  = Use64BitCounters(coder);

    // Allocate the profile buffer. It will hold single FuntimeRecord per each thread bucket
    uint32_t numThreadBuckets = (knobNumThreadBuckets == 0) ? genModel.MaxThreadBuckets() : knobNumThreadBuckets;
    uint32_t numTiles         = (knobPerTileProfiling && coder.IsTileIdSupported()) ? genArch.MaxTiles(kernel.GpuPlatform()) : 1;
    uint32_t numThreads       = genModel.NumThreads();
    GtProfileArray profileArray(sizeof(FuntimeRecord), numTiles, numThreadBuckets, numThreads);
    profileArray.Allocate(allocator);

    // Initialize virtual registers
    _timeReg   = vregs.Make(VREG_TYPE_DWORD);
    _dataReg   = vregs.MakeMsgDataScratch(is64BitCounter ? VREG_TYPE_QWORD : VREG_TYPE_DWORD);

    const IGtIns* begin = nullptr;
    const IGtIns* end = nullptr;
    for (auto bb : cfg.Bbls()) for (auto ins : bb->Instructions()) {
        auto off = cfg.GetInstructionOffset(*ins);
        if (off == static_cast<uint32_t>(knobStartPC.GetValue())) begin = ins;
        if (knobEndPC.GetValue() >= 0 && off == static_cast<uint32_t>(knobEndPC.GetValue())) end = ins;
        if (knobEndPC.GetValue() < 0 && ins->IsEot()) end = ins;
    }
    GTPIN_ASSERT_MSG(begin && end, "phaseclock: requested original PC not found");
    GtGenProcedure preCode;
    if (knobClockOnly) preCode += coder.InstructionFactory().MakeMov(_timeReg, 0);
    else coder.StartTimer(preCode, _timeReg);
    GtGenProcedure stopCode;
    if (knobClockOnly) stopCode += coder.InstructionFactory().MakeMov(_timeReg, 1);
    else coder.StopTimer(stopCode, _timeReg);
    // Same-PC null interval is one procedure: preserve timer read ordering.
    if (begin == end) {
        preCode += stopCode;
        instrumentor.InstrumentInstruction(*begin, GtIpoint::Before(), preCode);
    } else {
        instrumentor.InstrumentInstruction(*begin, GtIpoint::Before(), preCode);
        instrumentor.InstrumentInstruction(*end, GtIpoint::Before(), stopCode);
    }
    GtGenProcedure postCode;
    GeneratePostCode(postCode, coder, profileArray, numTiles, numThreadBuckets);
    if (knobImmediateReport) instrumentor.InstrumentInstruction(*end, GtIpoint::Before(), postCode);
    else instrumentor.InstrumentExits(postCode);
    // No fake data consumers, new barriers, or shader arithmetic changes.
    _kernels.emplace(kernel.Id(), FuntimeKernelProfile(kernel, profileArray));
}

void Funtime::OnKernelRun(IGtKernelDispatch& dispatcher)
{
    bool isProfileEnabled = false;

    const IGtKernel& kernel = dispatcher.Kernel();
    GtKernelExecDesc execDesc; dispatcher.GetExecDescriptor(execDesc);
    if (kernel.IsInstrumented() && IsKernelExecProfileEnabled(execDesc, kernel.GpuPlatform(), kernel.Name().Get()))
    {
        auto it = _kernels.find(kernel.Id());

        if (it != _kernels.end())
        {
            IGtProfileBuffer*       buffer          = dispatcher.CreateProfileBuffer(); GTPIN_ASSERT(buffer);
            FuntimeKernelProfile&   kernelProfile   = it->second;
            const GtProfileArray&   profileArray    = kernelProfile.GetProfileArray();
            if (profileArray.Initialize(*buffer))
            {
                isProfileEnabled = true;
            }
            else
            {
                GTPIN_ERROR_MSG(string("FUNTIME : ") + string(kernel.Name()) + " : Failed to write into memory buffer");
            }
        }
    }
    dispatcher.SetProfilingMode(isProfileEnabled);
}

void Funtime::OnKernelComplete(IGtKernelDispatch& dispatcher)
{
    const IGtKernel& kernel = dispatcher.Kernel();
    GtKernelExecDesc execDesc; dispatcher.GetExecDescriptor(execDesc);
    bool isProfilingEnabled = dispatcher.IsProfilingEnabled();
    if (!isProfilingEnabled || !IsKernelExecProfileEnabled(execDesc, kernel.GpuPlatform(), kernel.Name().Get()))
    {
        return; // Do nothing with unprofiled kernel dispatches
    }

    auto it = _kernels.find(kernel.Id());

    if (it != _kernels.end())
    {
        const IGtProfileBuffer* buffer          = dispatcher.GetProfileBuffer(); GTPIN_ASSERT(buffer);
        FuntimeKernelProfile&   kernelProfile   = it->second;
        const GtProfileArray&   profileArray    = kernelProfile.GetProfileArray();

        uint32_t numTiles = profileArray.NumRecords(); // There is a single record for each tile in each thread bucket
        for (uint32_t tileId = 0; tileId < numTiles; tileId++)
        {
            FuntimeDispatchProfile& dispatchProfile = kernelProfile.AddKernelDispatch(dispatcher, tileId);

            for (uint32_t threadBucket = 0; threadBucket < profileArray.NumThreadBuckets(); ++threadBucket)
            {
                for (uint32_t thread = 0; thread < profileArray.NumThreads(); ++thread)
                {
                    FuntimeRecord record;
                    if (!profileArray.Read(*buffer, &record, tileId, 1, threadBucket, thread))
                    {
                        GTPIN_ERROR_MSG(string("FUNTIME : ") + string(kernel.Name()) + " : Failed to read from memory buffer");
                    }
                    else
                    {
                        dispatchProfile.Accumulate(record);
                    }
                }
            }
        }
    }
}

void Funtime::OnFini()
{
    Funtime&    me     = *Instance();
    string profileDir  = GTPin_GetCore()->ProfileDir();

    GtOutputFormat format    = knobOutputFormat != "" ? knobOutputFormat.GetValue() : "txt";
    string         extension = format.GetFileExtension();
    string         file      = "phaseclock" + extension;
    string         filePath  = JoinPath(profileDir, file);

    ofstream fs(filePath, format == OutputFormat::BIN ? ios::binary : std::ios::out);
    if (fs.is_open())
    {
        fs << me.ToString();
        fs.close();
    }
    else
    {
        GTPIN_WARNING("FUNTIME : could not create file: " + filePath);
    }
}

string Funtime::ToString() const
{
    ostringstream ostr;

    // Set output format - if knob is not set, use txt format
    GtOutputFormat    format = knobOutputFormat != "" ? knobOutputFormat.GetValue() : "txt";
    GtOutputGenerator outputGenerator(format);

    // Define output descriptors
    OutputDescriptor outputDesc;

    // Fill description
    outputDesc.description = "### Kernel/Shader execution-time profile generated by GTPin ###\n\nLegend:\nNA - kernel was not instrumented.\n\n";

    // Fill format descriptor
    outputDesc.formatDesc = FormatDescriptor(format);

    // Fill field descriptors
    outputDesc.descriptors = {
        {"Name",                 30 },
        {"HashID",               20, true, NumericFormat::Hex},
        {"SIMD",                 10 },
        {"Type",                 10 },
        {"Freq.",                15 },
        {"Total-Cycle",          15 },
        {"Avg-Cycles",           15 },
        {"Skipped",              15 },
        {"Platform",             20 },
        {"Tile",                 10, knobPerTileProfiling.GetValue() },
        {"Execution Descriptor", 35 }
    };

    // Collect all records
    RecordList records;

    for (const auto& kernelEntry : _kernels)
    {
        RecordList kernelRecords = kernelEntry.second.ToRecords();
        records.insert(records.end(), kernelRecords.begin(), kernelRecords.end());
    }

    bool res = outputGenerator.GenerateOutput(records, outputDesc, ostr);
    GTPIN_ASSERT_MSG(res, "FUNTIME : Failed to generate output");

    return ostr.str();
}

bool Funtime::Use64BitCounters(const IGtGenCoder& coder)
{
    return coder.InstructionFactory().CanAccessAtomically(GED_DATA_TYPE_uq);
}

void Funtime::GeneratePreCode(GtGenProcedure& proc, const IGtGenCoder& coder)
{
    coder.StartTimer(proc, _timeReg);
    if (!proc.empty()) { proc.front()->AppendAnnotation(__func__); }
}

void Funtime::GeneratePostCode(GtGenProcedure& proc,
                               const IGtGenCoder& coder,
                               const GtProfileArray& profileArray,
                               const uint32_t numTiles,
                               const uint32_t numThreadBuckets)
{
    IGtInsFactory&  insF            = coder.InstructionFactory();
    bool            is64BitCounter  = Use64BitCounters(coder);

    GtReg           dataRegL        = {_dataReg, sizeof(uint32_t), 0};  // Low 32-bits of the data payload register

    // Generate code that computes elapsed time, and sets flagReg in case of timer overflow
    // Interval was stopped at its endpoint. Deferred report does not read timer again.

    if (!proc.empty()) { proc.front()->AppendAnnotation(__func__); }

    GtReg addrReg, offsetReg;
    profileArray.ComputeThreadChunkAddressAndOffsetRegs(coder, proc, addrReg, offsetReg);
    GTPIN_ASSERT(addrReg.IsValid() && offsetReg.IsValid());

    if (numTiles > 1)
    {
        // The record number = tile ID
        GtReg tileIdReg = coder.VregFactory().MakeScratch();
        coder.LoadTileId(proc, tileIdReg);
        proc += insF.MakeMul(tileIdReg, tileIdReg, numThreadBuckets * sizeof(FuntimeRecord));
        proc += insF.MakeAdd(offsetReg, offsetReg, tileIdReg);
    }

    if (_dataReg.ElementSize() == 8)
    {
        coder.ClearReg64(proc, _dataReg);
    }

    proc += insF.MakeMov(dataRegL, _timeReg);

    coder.PerformAtomicAdd(proc, _dataReg, addrReg, offsetReg, _dataReg, offsetof(FuntimeRecord, cycles), (is64BitCounter ? GED_DATA_TYPE_uq : GED_DATA_TYPE_ud));
    coder.PerformAtomicInc(proc, NullReg(), addrReg, offsetReg, offsetof(FuntimeRecord, freq),   GED_DATA_TYPE_ud);
    // skipped remains zero; modulo-32 timer, reject durations near wrap externally.
}

/* ============================================================================================= */
// FuntimeDispatchProfile implementation
/* ============================================================================================= */
FuntimeDispatchProfile::FuntimeDispatchProfile(const IGtKernelDispatch& kernelDispatch, uint32_t tile) :
    tileId(tile), cycles(0), freq(0), skipped(0)
{
    kernelDispatch.GetExecDescriptor(kernelExecDesc);
}

void FuntimeDispatchProfile::Accumulate(const FuntimeRecord& record)
{
    cycles  += record.cycles;
    freq    += record.freq;
    skipped += record.skipped;
}

/* ============================================================================================= */
// FuntimeKernelProfile implementation
/* ============================================================================================= */
FuntimeKernelProfile::FuntimeKernelProfile(const IGtKernel& kernel, const GtProfileArray& profileArray) :
    _name(GlueString(kernel.Name())), _type(kernel.Type()), _platform(kernel.GpuPlatform()), _hashId(kernel.HashId()),
    _simd(kernel.SimdWidth()), _profileArray(profileArray) {}

FuntimeDispatchProfile& FuntimeKernelProfile::AddKernelDispatch(const IGtKernelDispatch& kernelDispatch, const uint32_t tile)
{
    _dispatchProfiles.emplace_back(kernelDispatch, tile);
    return _dispatchProfiles.back();
}

RecordList FuntimeKernelProfile::ToRecords() const
{
    RecordList records;

    if (!_dispatchProfiles.empty())
    {

        for (const auto& dp: _dispatchProfiles)
        {
            if (knobSkipZeroResults && (dp.freq == 0))
            {
                continue; // Skip zero results if the knob is set
            }

            // Create record
            string   execDesStr = dp.kernelExecDesc.ToString(_platform, ExecDescAlignedFormat());
            uint64_t avgCycles  = (dp.freq ? (dp.cycles / dp.freq) : 0);
            uint32_t tileId     = knobPerTileProfiling ? dp.tileId : 0 ;

            Record kernelRecord {
                    _name,
                    _hashId,
                    _simd.ToString(),
                    _type.ToString(),
                    dp.freq,
                    dp.cycles,
                    avgCycles,
                    dp.skipped,
                    _platform.ToString(),
                    tileId,
                    execDesStr
            };

            // Save record
            records.push_back(kernelRecord);
        }
    }
    else
    {
        Record emptyKernelRecord {
                _name,
                _hashId,
                _simd.ToString(),
                _type.ToString(),
                "NA",
                "NA",
                "NA",
                "NA",
                "NA",
                "NA",
                "NA"
            };

        records.push_back(emptyKernelRecord);
    }

    return records;
}

string FuntimeKernelProfile::ToString() const
{
    ostringstream ostr;

    bool hasNonZeroResults = any_of(_dispatchProfiles.begin(), _dispatchProfiles.end(),
                                    [](const FuntimeDispatchProfile& dp) 
                                    { return dp.freq > 0; });
    if (!_dispatchProfiles.empty())
    {
        for (const auto& dp: _dispatchProfiles)
        {
            if (knobSkipZeroResults && (dp.freq == 0))
            {
                continue; // Skip zero results if the knob is set
            }

            uint64_t avgCycles = (dp.freq ? (dp.cycles / dp.freq) : 0);

            ostr << setw(30) << _name << setw(20) << hex << _hashId << dec << setw(10) << _simd << setw(10) << _type.ToString();
            ostr << setw(15) << dp.freq << setw(15) << dp.cycles << setw(15) << avgCycles << setw(15) << dp.skipped;
            ostr << setw(20) << _platform.ToString();
            if (knobPerTileProfiling)
            {
                ostr << setw(10) << dp.tileId;
            }
            ostr << " " << setw(35) << dp.kernelExecDesc.ToString(_platform, ExecDescAlignedFormat());
            ostr << endl;
        }

        if (!knobSkipZeroResults || hasNonZeroResults)
        {
            ostr << endl;
        }
    }
    else
    {
        ostr << setw(30) << _name << setw(20) << hex << _hashId << dec << setw(10) << _simd << setw(10) << _type.ToString();
        ostr << setw(15) << "NA" << setw(15) << "NA" << setw(15) << "NA" << setw(15) << "NA" << setw(20) << "NA";
        if (knobPerTileProfiling)
        {
            ostr << setw(10) << "NA";
        }
        ostr << " " << setw(35) << "NA"  << endl << endl;
    }
    return ostr.str();
}

/* ============================================================================================= */
// GTPin_Entry
/* ============================================================================================= */
EXPORT_C_FUNC void GTPin_Entry(int argc, const char *argv[])
{
    ConfigureGTPin(argc, argv);
    Funtime::Instance()->Register();
    atexit(Funtime::OnFini);
}
