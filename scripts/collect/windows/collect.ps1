<#
Windows 에서만 읽을 수 있는 자료(Outlook 일정·메일, Teams 채팅, 회의 전사, 이 PC 채팅)를 모아 records/ 에 넣는다.
AI 를 부르지 않는다. 브리핑·일지를 쓰는 일은 실행기(scripts/run/work-auto.sh)가 한다.

이 스크립트는 자기 위치를 기준으로 레포를 찾는다. 레포가 네트워크 공유 폴더에 있으면 그 폴더에 바로 쌓인다.

사용:
    powershell -File scripts/collect/windows/collect.ps1 <morning|evening|transcripts> [YYYY-MM-DD]

    morning      오늘 Outlook 일정·읽지 않은 메일, 직전 근무일 이후 Teams 채팅, 직전 근무일 이 PC 채팅, 새 전사
    evening      그날 Outlook 일정, 그날 이 PC 채팅, 새 전사
    transcripts  새 회의 전사만 records/inbox/transcripts/ 로 복사 (근무 시간에 몇 분마다 돈다)

- 설정은 config/company.env 에서 읽는다 (없으면 config/company.example.env).
- 주말·records/_system/state/holidays.txt 날짜면 아무것도 하지 않는다 (날짜 인자를 주면 이 검사를 건너뛴다).
- 한 단계가 실패해도 다음 단계로 간다. 단계마다 결과를 records/_system/state/runs.tsv 에 한 줄씩 남긴다.
#>
param(
    [Parameter(Position = 0)][string]$Mode = '',
    [Parameter(Position = 1)][string]$Day = ''
)

$ErrorActionPreference = 'Stop'

$Here = $PSScriptRoot
$Repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Here))
$Records = Join-Path $Repo 'records'
$State = Join-Path $Records '_system\state'
$Src = Join-Path $Records '_system\sources'
$Runs = Join-Path $State 'runs.tsv'
$Holidays = Join-Path $State 'holidays.txt'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

if ($Mode -notin 'morning', 'evening', 'transcripts') {
    Write-Error '사용: collect.ps1 <morning|evening|transcripts> [YYYY-MM-DD]'
    exit 2
}
$Force = [bool]$Day
if (-not $Day) { $Day = Get-Date -Format 'yyyy-MM-dd' }
if ($Day -notmatch '^\d{4}-\d{2}-\d{2}$') { Write-Error "날짜 형식 오류: $Day"; exit 2 }

# 1. 설정 읽기: KEY=VALUE, 양식 값 위에 회사 값을 덮는다.
$Cfg = @{}
foreach ($f in 'config\company.example.env', 'config\company.env') {
    $p = Join-Path $Repo $f
    if (-not (Test-Path $p)) { continue }
    foreach ($line in [IO.File]::ReadAllLines($p, $Utf8)) {
        if ($line -match '^\s*([A-Za-z0-9_]+)=(.*)$') { $Cfg[$Matches[1]] = $Matches[2].Trim() }
    }
}
$env:MY_NAME = $Cfg['MY_NAME']

function Add-Run([string]$Job, [string]$Result, [string]$Detail) {
    New-Item -ItemType Directory -Force -Path $State | Out-Null
    $line = "{0}`t{1}`t{2}`t{3}`t{4}`n" -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $env:COMPUTERNAME, $Job, $Result, $Detail
    [IO.File]::AppendAllText($Runs, $line, $Utf8)
}

function Test-Workday([string]$D) {
    $dow = [datetime]::ParseExact($D, 'yyyy-MM-dd', $null).DayOfWeek
    if ($dow -eq 'Saturday' -or $dow -eq 'Sunday') { return $false }
    if ((Test-Path $Holidays) -and (Select-String -Path $Holidays -Pattern "^$D(\s|$)" -Encoding UTF8 -Quiet)) { return $false }
    return $true
}

if (-not $Force -and -not (Test-Workday $Day)) { "$Day 주말·휴무, 건너뜀"; exit 0 }

$Prev = [datetime]::ParseExact($Day, 'yyyy-MM-dd', $null)
do { $Prev = $Prev.AddDays(-1) } until (Test-Workday $Prev.ToString('yyyy-MM-dd'))
$Prev = $Prev.ToString('yyyy-MM-dd')

# 2. 단계 실행기: 같은 폴더의 수집 스크립트를 부르고 결과를 runs.tsv 에 남긴다.
function Invoke-Step([string]$Job, [string]$Script, [string[]]$StepArgs) {
    $ErrorActionPreference = 'Continue'
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Here $Script) @StepArgs 2>&1
    $rc = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $last = ($out | ForEach-Object { "$_" } | Where-Object { $_.Trim() } | Select-Object -First 1)
    if ($last.Length -gt 160) { $last = $last.Substring(0, 160) }
    if ($rc -eq 0) { Add-Run $Job 'ok' $last } else { Add-Run $Job 'fail' "종료 코드 $rc. $last" }
}

# 3. 새 회의 전사 복사. 처리된 전사는 inbox 에서 회의 폴더로 옮겨지므로, 이미 보낸 이름을 따로 적어 두고 다시 보내지 않는다.
function Copy-Transcripts {
    $dir = $Cfg['RECORDING_DIR']
    if (-not $dir) { return }
    if (-not (Test-Path $dir)) { Add-Run 'collect-transcripts' 'fail' "녹음 폴더 없음: $dir"; return }
    $inbox = Join-Path $Records 'inbox\transcripts'
    New-Item -ItemType Directory -Force -Path $inbox | Out-Null
    $seenFile = Join-Path $State 'transcripts-seen.txt'
    $seen = @()
    if (Test-Path $seenFile) { $seen = [IO.File]::ReadAllLines($seenFile, $Utf8) }
    $cutoff = (Get-Date).AddDays(-7)
    $n = 0; $a = 0
    Get-ChildItem -Path $dir -Filter '*.transcript.txt' -File |
        Where-Object { $_.LastWriteTime -ge $cutoff -and $_.Name -notin $seen -and $_.LastWriteTime -lt (Get-Date).AddMinutes(-1) } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $inbox $_.Name)
            # 녹음 파일도 같이 보낸다(COPY_RECORDINGS=1). 전사와 이름이 같고 확장자만 다른 파일이다.
            if ($Cfg['COPY_RECORDINGS'] -eq '1') {
                $stem = $_.Name -replace '\.transcript\.txt$', ''
                foreach ($ext in 'webm', 'm4a', 'mp3', 'wav') {
                    $audio = Join-Path $dir "$stem.$ext"
                    if (Test-Path -LiteralPath $audio) { Copy-Item -LiteralPath $audio -Destination (Join-Path $inbox "$stem.$ext"); $a++ }
                }
            }
            [IO.File]::AppendAllText($seenFile, $_.Name + "`n", $Utf8)
            $n++
        }
    if ($n -gt 0) { Add-Run 'collect-transcripts' 'ok' "새 전사 ${n}건, 녹음 ${a}건 -> records/inbox/transcripts/" }
}

try { Copy-Transcripts } catch { Add-Run 'collect-transcripts' 'fail' "$($_.Exception.Message)" }
if ($Mode -eq 'transcripts') { exit 0 }

# 4. Outlook
if ($Cfg['COLLECT_OUTLOOK'] -eq '1') { Invoke-Step 'collect-outlook' 'outlook-agenda.ps1' @('-Date', $Day) }

# 5. Teams (아침에만. 방을 열어 읽으므로 읽음 처리된다. Teams 앱이 열려 있어야 한다)
if ($Mode -eq 'morning' -and $Cfg['COLLECT_TEAMS'] -eq '1') {
    $top = if ($Cfg['TEAMS_TOP']) { $Cfg['TEAMS_TOP'] } else { '20' }
    Invoke-Step 'collect-teams' 'teams-chats.ps1' @('-Top', $top, '-Since', $Prev, '-ScrollPages', '1',
        '-Out', "records/_system/sources/teams/$Day-brief.md")
}

# 6. 이 PC 의 Claude Code 채팅·커밋 (아침은 직전 근무일, 저녁은 그날). cmd 리다이렉트는 바이트를 그대로 쓴다(UTF-8 유지).
$py = (Get-Command python -ErrorAction SilentlyContinue).Source
if ($py) {
    $d = if ($Mode -eq 'morning') { $Prev } else { $Day }
    $chatDir = Join-Path $Src 'chat'
    New-Item -ItemType Directory -Force -Path $chatDir | Out-Null
    $target = Join-Path $chatDir "$d-windows.md"
    & cmd /c "`"$py`" -I `"$Repo\scripts\chatlog_extract.py`" $d > `"$target`""
    if ($LASTEXITCODE -eq 0) { Add-Run 'collect-chat' 'ok' "$d" } else { Add-Run 'collect-chat' 'fail' "종료 코드 $LASTEXITCODE ($d)" }
}
