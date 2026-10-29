param(
 [Parameter(Mandatory=$true)][string]$Runner,
 [Parameter(Mandatory=$true)][string]$Plan,
 [Parameter(Mandatory=$true)][string]$Out,
 [Parameter(Mandatory=$true)][string]$Lock,
 [ValidateRange(0,1000)][int]$Warm=0,
 [ValidateRange(1,10000)][int]$Reps=1,
 [switch]$Feedback,[switch]$SaveFrames,[switch]$DumpIntermediates,[switch]$PerPassTiming,
 [string]$OutputFile='frame_out.bin',[string]$ExpectedOutputSha256=''
)
$ErrorActionPreference='Stop'
$Runner=(Resolve-Path -LiteralPath $Runner).Path
$Plan=(Resolve-Path -LiteralPath $Plan).Path
$Out=[IO.Path]::GetFullPath($Out)
$Lock=[IO.Path]::GetFullPath($Lock)
if(Test-Path -LiteralPath $Out){throw 'Use a fresh output directory'}
if(Get-Process -Name Cyberpunk2077,REDlauncher -ErrorAction SilentlyContinue){throw 'Close the game before offline GPU work'}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Lock))|Out-Null
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Out))|Out-Null
$stream=[IO.File]::Open($Lock,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$owned=$false
function WriteState($state){
 $bytes=[Text.Encoding]::UTF8.GetBytes(($state|ConvertTo-Json -Depth 8))
 $stream.Position=0;$stream.SetLength(0);$stream.Write($bytes,0,$bytes.Length);$stream.Flush()
}
try {
 if($stream.Length){
  $bytes=New-Object byte[] ([int]$stream.Length);[void]$stream.Read($bytes,0,$bytes.Length)
  $old=[Text.Encoding]::UTF8.GetString($bytes)|ConvertFrom-Json
  if($old.state -eq 'RUNNING'){throw 'Lock state is RUNNING; inspect the recorded owner/process before reclaiming it'}
 }
 $state=[ordered]@{state='RUNNING';holder_pid=$PID;owner='portable-experiment';started_utc=[DateTime]::UtcNow.ToString('o');plan=$Plan;output=$Out}
 WriteState $state;$owned=$true
 $argv=@('--plan',$Plan,'--out',$Out,'--pool','--warm',"$Warm",'--reps',"$Reps")
 if($Feedback){$argv+='--feedback'};if($SaveFrames){$argv+='--save-frames'}
 if($DumpIntermediates){$argv+='--dump-intermediates'};if($PerPassTiming){$argv+='--per-pass-timing'}
 $record=[ordered]@{runner_sha256=(Get-FileHash -LiteralPath $Runner).Hash;plan_sha256=(Get-FileHash -LiteralPath $Plan).Hash;argv=$argv;started_utc=$state.started_utc;status='RUNNING'}
 & $Runner @argv *> ($Out+'.console.txt')
 $record.exit_code=$LASTEXITCODE
 $receipt=Get-Content -LiteralPath (Join-Path $Out 'port_network_receipt.json') -Raw|ConvertFrom-Json
 if($record.exit_code -ne 0 -or -not $receipt.normal_close -or $receipt.nan -ne 0 -or $receipt.inf -ne 0){throw 'Runner/finite-output gate failed; retain logs'}
 if($ExpectedOutputSha256){
  $actual=(Get-FileHash -LiteralPath (Join-Path $Out $OutputFile)).Hash.ToLowerInvariant()
  $record.output_sha256=$actual
  if($actual -ne $ExpectedOutputSha256.ToLowerInvariant()){throw 'Output hash mismatch'}
 }
 $record.status='COMPLETED'
} catch {
 if($record){$record.status='FAILED';$record.error=$_.Exception.Message}
 throw
} finally {
 if($owned){
  $state.state='FINISHED';$state.finished_utc=[DateTime]::UtcNow.ToString('o')
  if($record){$state.result=$record.status;$record.finished_utc=$state.finished_utc;[IO.File]::WriteAllText($Out+'.execution.json',($record|ConvertTo-Json -Depth 8))}
  WriteState $state
 }
 $stream.Dispose()
}
