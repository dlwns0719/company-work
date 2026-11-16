<#
출근 브리핑·퇴근 일지를 사람 없이 만든다 (Windows 작업 스케줄러가 부른다).

수집과 작성을 이 스크립트 하나가 순서대로 한다. 자료를 다 모은 뒤에 Claude 를 띄우므로, 자료가 덜 모인 채로
브리핑이 써지는 일이 없다.

    1. 수집   collect.ps1 (Outlook 일정·메일, Teams 채팅, 회의 전사·녹음, 이 PC 채팅)
    2. 수집   Linux PC 의 채팅·커밋 (LINUX_HOST 가 설정돼 있을 때, SSH)
    3. 작성   claude -p "/day-start" 또는 "/daily-log" (--auto)
    4. 알림   Windows 알림, LINUX_NOTIFY=1 이면 Linux 바탕화면에도

사용:
    powershell -File scripts/run/windows/work-auto.ps1 <day-start|daily-log> [YYYY-MM-DD]

- 레포는 이 스크립트 위치를 기준으로 찾는다. 레포가 네트워크 공유(\\서버\공유\...)에 있으면 결과가 그 폴더에 바로 쌓인다.
  config 의 REPO_DRIVE(예: Z:)가 있으면 공유를 그 드라이브로 연결해 그 경로에서 Claude 를 돌린다.
- 주말·records/_system/state/holidays.txt 날짜면 아무것도 하지 않는다 (날짜 인자를 주면 이 검사를 건너뛴다).
- 결과 파일이 이미 있으면 건너뛴다. 다시 만들려면 그 파일을 옮기거나 지운다.
- Claude 는 사용자 설정 없이(--setting-sources project) 띄우고, 쓸 수 있는 파일을 그날 결과 파일로 좁힌다.
- 모든 단계의 결과가 records/_system/state/runs.tsv 에 한 줄씩 남는다.
#>
param(
    [Parameter(Position = 0)][string]$Skill = '',
    [Parameter(Position = 1)][string]$Day = ''
)

$ErrorActionPreference = 'Stop'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

switch ($Skill) {
    'day-start' { $Kind = 'brief'; $Title = '출근 브리핑'; $Mode = 'morning' }
    'daily-log' { $Kind = 'log'; $Title = '일지'; $Mode = 'evening' }
    default { Write-Error '사용: work-auto.ps1 <day-start|daily-log> [YYYY-MM-DD]'; exit 2 }
}
$Force = [bool]$Day
if (-not $Day) { $Day = Get-Date -Format 'yyyy-MM-dd' }
if ($Day -notmatch '^\d{4}-\d{2}-\d{2}$') { Write-Error "날짜 형식 오류: $Day"; exit 2 }

# 1. 설정 읽기
$Cfg = @{}
foreach ($f in 'config\company.example.env', 'config\company.env') {
    $p = Join-Path $Repo $f
    if (-not (Test-Path $p)) { continue }
    foreach ($line in [IO.File]::ReadAllLines($p, $Utf8)) {
        if ($line -match '^\s*([A-Za-z0-9_]+)=(.*)$') { $Cfg[$Matches[1]] = $Matches[2].Trim() }
    }
}

# 레포가 공유 경로에 있고 REPO_DRIVE 가 있으면 드라이브로 연결해 그 경로를 쓴다(저장된 자격 증명 사용).
$Work = $Repo
if ($Repo -match '^(\\\\[^\\]+\\[^\\]+)(.*)$' -and $Cfg['REPO_DRIVE']) {
    $share = $Matches[1]; $rest = $Matches[2]; $drive = $Cfg['REPO_DRIVE'].TrimEnd('\')
    if (-not (Test-Path "$drive\")) { & net use $drive $share /persistent:no | Out-Null }
    if (Test-Path "$drive$rest") { $Work = "$drive$rest" }
}

$Records = Join-Path $Work 'records'
$State = Join-Path $Records '_system\state'
$Runs = Join-Path $State 'runs.tsv'
$Holidays = Join-Path $State 'holidays.txt'
$Month = $Day.Substring(0, 7)
$OutRel = "records/daily/$Month/$Day-$Kind.md"
$OutFile = Join-Path $Work $OutRel
$LogDir = Join-Path $Records "_system\logs\$Month"
$Marker = '[work-auto]'

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

$SshOpt = @('-n', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=2')

function Send-Notice([string]$Head, [string]$Body) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $icon = New-Object System.Windows.Forms.NotifyIcon
        $icon.Icon = [System.Drawing.SystemIcons]::Information
        $icon.Visible = $true
        $icon.ShowBalloonTip(10000, $Head, $Body, 'Info')
        Start-Sleep -Seconds 10
        $icon.Dispose()
    } catch { }
    # Linux 바탕화면 알림: 한글이 SSH 인자에서 깨지지 않게 결과 파일 경로와 날짜만 보낸다.
    if ($Cfg['LINUX_NOTIFY'] -eq '1' -and $Cfg['LINUX_HOST']) {
        $state = if ($Head -match '실패|초과') { 'FAILED' } else { 'ready' }
        $cmd = 'DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus notify-send -a work ' +
               "'work: $Skill $Day $state' '$OutRel'"
        try { & ssh @SshOpt $Cfg['LINUX_HOST'] $cmd 2>$null | Out-Null } catch { }
    }
}

if (-not $Force -and -not (Test-Workday $Day)) { "$Day 주말·휴무, 건너뜀"; exit 0 }
if (Test-Path $OutFile) {
    "$OutRel 이미 있음, 건너뜀"
    Add-Run $Skill 'skip' "$OutRel 이미 있음"
    exit 0
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile), $LogDir | Out-Null
$Log = Join-Path $LogDir "$Day-$Skill.log"
$ErrLog = Join-Path $LogDir "$Day-$Skill.err.log"

# 2. 수집 (실패해도 계속). collect.ps1 이 단계마다 runs.tsv 에 남긴다.
$ErrorActionPreference = 'Continue'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo 'scripts\collect\windows\collect.ps1') $Mode $Day 2>&1 | Out-Null
$ErrorActionPreference = 'Stop'

# 3. Linux PC 의 채팅·커밋. 아침은 직전 근무일(전날 일지를 쓴 뒤의 활동), 저녁은 그날.
#    Linux 에서 바로 레포 안에 쓰게 한다. 레포가 Linux 의 공유 폴더에 있으면 그대로 이 PC 에서도 보인다.
if ($Cfg['LINUX_HOST'] -and $Cfg['LINUX_REPO']) {
    $d = $Day
    if ($Skill -eq 'day-start') {
        $prev = [datetime]::ParseExact($Day, 'yyyy-MM-dd', $null)
        do { $prev = $prev.AddDays(-1) } until (Test-Workday $prev.ToString('yyyy-MM-dd'))
        $d = $prev.ToString('yyyy-MM-dd')
    }
    $remote = "cd $($Cfg['LINUX_REPO']) && mkdir -p records/_system/sources/chat && " +
              "python3 -I scripts/chatlog_extract.py $d > records/_system/sources/chat/$d-linux.md"
    $ErrorActionPreference = 'Continue'
    & ssh @SshOpt $Cfg['LINUX_HOST'] $remote 2>&1 | Out-Null
    $rc = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($rc -eq 0) { Add-Run 'collect-linux-chat' 'ok' $d } else { Add-Run 'collect-linux-chat' 'fail' "ssh 종료 코드 $rc ($d)" }
}

# 4. Claude 실행
$Claude = if ($Cfg['CLAUDE_BIN']) { $Cfg['CLAUDE_BIN'] } elseif ($env:CLAUDE_BIN) { $env:CLAUDE_BIN } else { Join-Path $env:USERPROFILE '.local\bin\claude.exe' }
$TimeoutMin = if ($Cfg['RUN_TIMEOUT_MIN']) { [int]$Cfg['RUN_TIMEOUT_MIN'] } else { 20 }
$allowed = @('Read', 'Glob', 'Grep', 'Bash(date:*)', "Edit(./$OutRel)")
if ($Skill -eq 'daily-log') { $allowed += 'Edit(./records/todo.md)' }
if ($Skill -eq 'day-start' -and $Cfg['TRACKER_GET_CMD']) {
    $allowed += "Bash($($Cfg['TRACKER_GET_CMD']):*)", "PowerShell($($Cfg['TRACKER_GET_CMD']):*)"
}
$denied = @('Read(./.env)', 'Read(./.env.*)', 'Agent', 'WebFetch', 'WebSearch', 'NotebookEdit')
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
$argv = @('-p', "/$Skill $Day --auto --at `"$now`" $Marker", '--setting-sources', 'project', '--permission-mode', 'dontAsk',
          '--allowedTools') + $allowed + @('--disallowedTools') + $denied
if ($Cfg['CLAUDE_MODEL']) { $argv += '--model', $Cfg['CLAUDE_MODEL'] }
# Windows PowerShell 5.1 의 Start-Process 는 인자를 따옴표 없이 이어 붙이므로 직접 감싼다.
$argLine = ($argv | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '

# Start-Process 리다이렉트는 바이트를 그대로 파일에 쓴다(PowerShell 의 UTF-16 변환을 피한다).
$proc = Start-Process -FilePath $Claude -ArgumentList $argLine -WorkingDirectory $Work -NoNewWindow -PassThru `
    -RedirectStandardOutput $Log -RedirectStandardError $ErrLog
$null = $proc.Handle   # 핸들을 미리 열어 두지 않으면 종료 후 ExitCode 가 비어 나온다
if (-not $proc.WaitForExit($TimeoutMin * 60 * 1000)) {
    try { $proc.Kill() } catch { }
    Add-Run $Skill 'fail' "시간 초과 (${TimeoutMin}분)"
    Send-Notice "$Title 시간 초과 ($Day)" "${TimeoutMin}분 안에 끝나지 않았다. 로그: records/_system/logs/$Month/$Day-$Skill.log"
    exit 1
}
$rc = $proc.ExitCode

# 성공해도 손봐야 할 경고(로그인 만료 예고, 모델 이름 오류 등)는 따로 남긴다.
$warn = Get-Content -Encoding UTF8 $ErrLog -ErrorAction SilentlyContinue |
    Where-Object { $_ -match 'sign-in|auth login|unrecognized_model|rate.?limit|expired' } | Select-Object -First 1
if ($warn) {
    if ($warn.Length -gt 160) { $warn = $warn.Substring(0, 160) }
    Add-Run $Skill 'warn' $warn
}

if ($rc -eq 0 -and (Test-Path $OutFile)) {
    # 요약 줄은 'n · n · n' 형식이다. 모델이 뒤에 다른 말을 덧붙여도 그 줄을 고른다.
    $lines = Get-Content -Encoding UTF8 $Log | Where-Object { $_.Trim() }
    $summary = ($lines | Where-Object { $_ -match ' · ' } | Select-Object -Last 1)
    if (-not $summary) { $summary = ($lines | Select-Object -Last 1) }
    if ($summary.Length -gt 200) { $summary = $summary.Substring(0, 200) }
    Add-Run $Skill 'ok' $summary
    Send-Notice "$Title 준비됨 ($Day)" "$summary`n$OutRel"
    exit 0
}

Add-Run $Skill 'fail' "종료 코드 $rc"
Send-Notice "$Title 실패 ($Day)" "종료 코드 $rc. 로그: records/_system/logs/$Month/$Day-$Skill.log"
exit 1
