<#
자동 실행을 Windows 작업 스케줄러에 등록한다. 수집과 브리핑·일지 작성을 모두 이 PC 가 한다.

    work-daystart     평일 MORNING_AT   work-auto.ps1 day-start   (수집 -> 브리핑)
    work-dailylog     평일 EVENING_AT   work-auto.ps1 daily-log   (수집 -> 일지)
    work-transcripts  평일 09:00 부터 10시간, TRANSCRIPT_EVERY_MIN 분마다   collect.ps1 transcripts (새 회의 전사·녹음 복사)

로그인한 사용자 세션에서만 돈다(Outlook COM 과 Teams 창이 사용자 세션을 요구한다). PC 가 꺼져 있어 놓친 실행은
켜진 뒤 한 번 돈다. 다시 실행하면 같은 이름의 작업을 새 설정으로 바꾼다.

레포가 네트워크 공유에 있으면 드라이브 문자(Z:)가 아니라 \\서버\공유\... 경로에서 이 스크립트를 실행해 등록한다.
그 전에 탐색기에서 공유를 열어 자격 증명을 저장해 둔다.

사용:
    powershell -ExecutionPolicy Bypass -File scripts/run/windows/register-tasks.ps1            등록
    powershell -ExecutionPolicy Bypass -File scripts/run/windows/register-tasks.ps1 -Remove    해제
#>
param([switch]$Remove)

$ErrorActionPreference = 'Stop'

$Repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$Runner = Join-Path $PSScriptRoot 'work-auto.ps1'
$Collector = Join-Path $Repo 'scripts\collect\windows\collect.ps1'
$Folder = '\work\'
$Names = 'work-daystart', 'work-dailylog', 'work-transcripts'

if ($Remove) {
    foreach ($n in $Names) {
        Unregister-ScheduledTask -TaskName $n -TaskPath $Folder -Confirm:$false -ErrorAction SilentlyContinue
        "해제: $n"
    }
    exit 0
}

$Cfg = @{}
$Utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($f in 'config\company.example.env', 'config\company.env') {
    $p = Join-Path $Repo $f
    if (-not (Test-Path $p)) { continue }
    foreach ($line in [IO.File]::ReadAllLines($p, $Utf8)) {
        if ($line -match '^\s*([A-Za-z0-9_]+)=(.*)$') { $Cfg[$Matches[1]] = $Matches[2].Trim() }
    }
}
$morning = if ($Cfg['MORNING_AT']) { $Cfg['MORNING_AT'] } else { '08:40' }
$evening = if ($Cfg['EVENING_AT']) { $Cfg['EVENING_AT'] } else { '17:20' }
$every = if ($Cfg['TRANSCRIPT_EVERY_MIN']) { [int]$Cfg['TRANSCRIPT_EVERY_MIN'] } else { 10 }
$limit = $(if ($Cfg['RUN_TIMEOUT_MIN']) { [int]$Cfg['RUN_TIMEOUT_MIN'] } else { 20 }) + 15

$Weekdays = 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

function Register-Work([string]$Name, [string]$Script, [string]$Arg, $Trigger, [int]$LimitMin, [string]$Desc) {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -WorkingDirectory $env:USERPROFILE `
        -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Script`" $Arg"
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Minutes $LimitMin) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName $Name -TaskPath $Folder -Description $Desc -Action $action `
        -Trigger $Trigger -Settings $settings -Principal $principal -Force | Out-Null
    "등록: $Name ($Desc)"
}

Register-Work 'work-daystart' $Runner 'day-start' `
    (New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $Weekdays -At $morning) $limit "평일 $morning 수집 후 출근 브리핑"
Register-Work 'work-dailylog' $Runner 'daily-log' `
    (New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $Weekdays -At $evening) $limit "평일 $evening 수집 후 퇴근 일지"

# 반복 설정은 한 번짜리 트리거에서 빌려 와 평일 트리거에 붙인다.
$tr = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $Weekdays -At '09:00'
$tr.Repetition = (New-ScheduledTaskTrigger -Once -At '09:00' -RepetitionInterval (New-TimeSpan -Minutes $every) `
    -RepetitionDuration (New-TimeSpan -Hours 10)).Repetition
if ($Cfg['RECORDING_DIR']) {
    Register-Work 'work-transcripts' $Collector 'transcripts' $tr 10 "평일 09:00 부터 ${every}분마다 새 회의 전사·녹음 복사"
} else {
    # 녹음 프로그램이 records/inbox/ 에 바로 저장하면 복사가 필요 없다.
    Unregister-ScheduledTask -TaskName 'work-transcripts' -TaskPath $Folder -Confirm:$false -ErrorAction SilentlyContinue
    '건너뜀: work-transcripts (RECORDING_DIR 비어 있음)'
}
