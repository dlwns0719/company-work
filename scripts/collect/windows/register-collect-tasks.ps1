<#
Windows 수집기를 작업 스케줄러에 등록한다. 브리핑·일지 실행(Linux 의 systemd 타이머)보다 10분 먼저 돈다.

    work-collect-morning      평일 MORNING_AT - 10분   collect.ps1 morning
    work-collect-evening      평일 EVENING_AT - 10분   collect.ps1 evening
    work-collect-transcripts  평일 09:00 부터 10시간, TRANSCRIPT_EVERY_MIN 분마다   collect.ps1 transcripts

로그인한 사용자 세션에서만 돈다(Outlook COM 과 Teams 창이 사용자 세션을 요구한다). PC 가 꺼져 있어 놓친 실행은
켜진 뒤 한 번 돈다. 다시 실행하면 같은 이름의 작업을 새 설정으로 바꾼다.

레포가 네트워크 공유에 있으면 드라이브 문자(Z:)가 아니라 \\서버\공유\... 경로에서 이 스크립트를 실행해 등록한다.
작업 스케줄러는 드라이브 문자를 보지 못한다.

사용:
    powershell -ExecutionPolicy Bypass -File scripts/collect/windows/register-collect-tasks.ps1            등록
    powershell -ExecutionPolicy Bypass -File scripts/collect/windows/register-collect-tasks.ps1 -Remove    해제
#>
param([switch]$Remove)

$ErrorActionPreference = 'Stop'

$Runner = Join-Path $PSScriptRoot 'collect.ps1'
$Repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$Folder = '\work\'
$Names = 'work-collect-morning', 'work-collect-evening', 'work-collect-transcripts'

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
function Get-Before([string]$Key, [string]$Default) {
    $v = if ($Cfg[$Key]) { $Cfg[$Key] } else { $Default }
    ([datetime]::ParseExact($v, 'HH:mm', $null)).AddMinutes(-10).ToString('HH:mm')
}
$every = if ($Cfg['TRANSCRIPT_EVERY_MIN']) { [int]$Cfg['TRANSCRIPT_EVERY_MIN'] } else { 10 }

$Weekdays = 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15) -MultipleInstances IgnoreNew

function Register-Collect([string]$Name, [string]$Mode, $Trigger, [string]$Desc) {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -WorkingDirectory $Repo `
        -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Runner`" $Mode"
    Register-ScheduledTask -TaskName $Name -TaskPath $Folder -Description $Desc -Action $action `
        -Trigger $Trigger -Settings $settings -Principal $principal -Force | Out-Null
    "등록: $Name ($Desc)"
}

$morning = Get-Before 'MORNING_AT' '08:40'
$evening = Get-Before 'EVENING_AT' '17:20'
Register-Collect 'work-collect-morning' 'morning' `
    (New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $Weekdays -At $morning) "평일 $morning 아침 수집"
Register-Collect 'work-collect-evening' 'evening' `
    (New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $Weekdays -At $evening) "평일 $evening 저녁 수집"

# 반복 설정은 한 번짜리 트리거에서 빌려 와 평일 트리거에 붙인다.
$tr = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $Weekdays -At '09:00'
$tr.Repetition = (New-ScheduledTaskTrigger -Once -At '09:00' -RepetitionInterval (New-TimeSpan -Minutes $every) `
    -RepetitionDuration (New-TimeSpan -Hours 10)).Repetition
Register-Collect 'work-collect-transcripts' 'transcripts' $tr "평일 09:00 부터 ${every}분마다 새 회의 전사 복사"
