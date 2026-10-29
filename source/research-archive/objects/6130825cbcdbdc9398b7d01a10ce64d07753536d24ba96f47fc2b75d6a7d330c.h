/*========================== begin_copyright_notice ============================
Copyright (C) 2018-2026 Intel Corporation

SPDX-License-Identifier: MIT
============================= end_copyright_notice ===========================*/

/*!
 * @file Funtime tool definitions
 */

#ifndef FUNTIME_H_
#define FUNTIME_H_

#include <list>
#include <map>
#include <set>
#include <string>

#include "gtpin_api.h"
#include "gtpin_tool_utils.h"
#include "gt_output_generator.h"

using namespace gtpin;

/* ============================================================================================= */
// Struct FuntimeRecord
/* ============================================================================================= */
/*!
 * Layout of records collected in profile buffer by the funtime tool
 */
struct FuntimeRecord
{
    uint64_t cycles;    ///< Total number of cycles
    uint32_t freq;      ///< Total number of executions
    uint32_t skipped;   ///< Total number of skipped executions
};

/* ============================================================================================= */
// Class FuntimeDispatchProfile
/* ============================================================================================= */
/*!
 * Profiling data collected during a single kernel dispatch
 */
struct FuntimeDispatchProfile
{
    explicit FuntimeDispatchProfile(const IGtKernelDispatch& kernelDispatch, uint32_t tile = 0);
    void Accumulate(const FuntimeRecord& record);

    GtKernelExecDesc  kernelExecDesc; ///< Kernel execution descriptor
    uint32_t          tileId;         ///< Identifier of the subdevice (tile) assigned to this kernel dispatch
    uint64_t          cycles;         ///< Total number of cycles
    uint64_t          freq;           ///< Total number of executions
    uint64_t          skipped;        ///< Total number of skipped executions
};

/* ============================================================================================= */
// Class FuntimeKernelProfile
/* ============================================================================================= */
/*!
 * Aggregated profile of all instrumented kernel dispatches
 */
class FuntimeKernelProfile
{
public:
    FuntimeKernelProfile(const IGtKernel& kernel, const GtProfileArray& profileArray);

    /// Add new dispatched kernel instance,  and return reference to its (empty) profile
    FuntimeDispatchProfile& AddKernelDispatch(const IGtKernelDispatch& kernelDispatch, uint32_t tile = 0);

    std::string           ToString()        const;                         ///< @return Text representation of the profile data
    RecordList            ToRecords()       const;                         ///< @return Profile data in RecordList format
    const GtProfileArray& GetProfileArray() const { return _profileArray; }///< @return Profile buffer accessor

private:
    std::string                         _name;              ///< Kernel's name
    GtKernelType                        _type;              ///< Kernel's type
    GtGpuPlatform                       _platform;          ///< Kernel's platform
    uint64_t                            _hashId;            ///< Kernel's hash identifier
    GtSimdWidth                         _simd;              ///< Kernel's SIMD width
    GtProfileArray                      _profileArray;      ///< Profile buffer accessor
    std::list<FuntimeDispatchProfile>   _dispatchProfiles;  ///< Profiles per kernel dispatch
};

/* ============================================================================================= */
// Class Funtime
/* ============================================================================================= */
/*!
 * Implementation of the IGtTool interface for the funtime tool
 */
class Funtime : public GtTool
{
public:
    /// Implementation of the IGtTool interface
    const char* Name() const { return "phaseclock"; }

    void OnKernelBuild(IGtKernelInstrument& instrumentor);
    void OnKernelRun(IGtKernelDispatch& dispatcher);
    void OnKernelComplete(IGtKernelDispatch& dispatcher);

public:
    static void OnFini();                        ///< Callback function registered with atexit()
    std::string ToString() const;                ///< @return Text representation of the profile data

    static Funtime* Instance();                  ///< @return Single instance of this class

private:
    Funtime() = default;
    Funtime(const Funtime&) = delete;
    Funtime& operator = (const Funtime&) = delete;
    ~Funtime() = default;

    /// Generate code at entry/exits of the kernel
    void GeneratePreCode(GtGenProcedure& proc, const IGtGenCoder& coder);
    void GeneratePostCode(GtGenProcedure& proc, const IGtGenCoder& coder, const GtProfileArray& profileArray, const uint32_t numTiles, const uint32_t numThreadBuckets);

    /// @return true/false - use 64-bit/32-bit integer for the cycle counter
    static bool Use64BitCounters(const IGtGenCoder& coder);

private:
    std::map<GtKernelId, FuntimeKernelProfile> _kernels;  ///< Collection of kernel profiles

    GtReg _dataReg;     ///< Virtual register that holds data to be read from/written to profile buffer
    GtReg _timeReg;     ///< Virtual timer register
};

#endif