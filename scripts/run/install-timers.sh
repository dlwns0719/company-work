#!/usr/bin/env bash
# 출근 브리핑·퇴근 일지 자동 실행을 systemd 사용자 타이머로 등록한다 (Linux, 실행기가 도는 PC).
#
# 사용:
#   bash scripts/run/install-timers.sh            등록 (다시 실행하면 새 설정으로 바꾼다)
#   bash scripts/run/install-timers.sh --remove   해제
#
# 시각은 config/company.env 의 MORNING_AT·EVENING_AT 을 쓴다. PC 가 꺼져 있어 놓친 실행은 켜진 뒤 한 번 돈다.
# 로그인한 동안에만 돈다. 로그아웃 상태에서도 돌리려면 `loginctl enable-linger $USER` 가 필요하다.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
. "$REPO/scripts/lib/config.sh"
UNIT_DIR="$HOME/.config/systemd/user"
JOBS=("work-daystart:day-start:$MORNING_AT:출근 브리핑" "work-dailylog:daily-log:$EVENING_AT:퇴근 일지")

if [ "${1:-}" = "--remove" ]; then
  for job in "${JOBS[@]}"; do
    name="${job%%:*}"
    systemctl --user disable --now "$name.timer" 2>/dev/null || true
    rm -f "$UNIT_DIR/$name.timer" "$UNIT_DIR/$name.service"
    echo "해제: $name"
  done
  systemctl --user daemon-reload
  exit 0
fi

mkdir -p "$UNIT_DIR"
for job in "${JOBS[@]}"; do
  IFS=: read -r name skill hh mm desc <<< "$job"
  cat > "$UNIT_DIR/$name.service" <<EOF
[Unit]
Description=work 자동 실행: $desc (/$skill --auto)

[Service]
Type=oneshot
WorkingDirectory=$REPO
ExecStart=$REPO/scripts/run/work-auto.sh $skill
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
TimeoutStartSec=$(( RUN_TIMEOUT_MIN + 5 ))min
EOF
  cat > "$UNIT_DIR/$name.timer" <<EOF
[Unit]
Description=work 자동 실행 시각: $desc (평일 $hh:$mm)

[Timer]
OnCalendar=Mon..Fri *-*-* $hh:$mm:00
Persistent=true
RandomizedDelaySec=60

[Install]
WantedBy=timers.target
EOF
  echo "등록: $name 평일 $hh:$mm"
done

systemctl --user daemon-reload
for job in "${JOBS[@]}"; do systemctl --user enable --now "${job%%:*}.timer"; done
systemctl --user list-timers 'work-*' --no-pager
