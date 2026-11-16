#!/usr/bin/env bash
# config/company.env 를 읽어 셸 변수로 올린다. 다른 스크립트가 `. scripts/lib/config.sh` 로 불러 쓴다.
# 파일이 없으면 양식(config/company.example.env)의 기본값으로 돈다. 값에 공백이 있어도 한 줄 전체를 값으로 읽는다.

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
RECORDS="$REPO/records"
STATE_DIR="$RECORDS/_system/state"
RUNS_FILE="$STATE_DIR/runs.tsv"

_load_env() {
  local file="$1" line key val
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in ''|'#'*) continue ;; esac
    key="${line%%=*}"; val="${line#*=}"
    case "$key" in *[!A-Za-z0-9_]*|'') continue ;; esac
    printf -v "$key" '%s' "$val"
  done < "$file"
}

_load_env "$REPO/config/company.example.env"
_load_env "$REPO/config/company.env"

CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
RUN_TIMEOUT_MIN="${RUN_TIMEOUT_MIN:-20}"
MORNING_AT="${MORNING_AT:-08:40}"
EVENING_AT="${EVENING_AT:-17:20}"

# 자동 실행 한 건의 결과를 한 줄로 남긴다. /ops-check 와 출근 브리핑이 이 파일을 읽는다.
# 사용: record_run <작업> <ok|skip|warn|fail> <설명>
record_run() {
  mkdir -p "$STATE_DIR"
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date '+%F %H:%M')" "$(hostname)" "$1" "$2" "${3:-}" >> "$RUNS_FILE"
}

# 근무일인가: 주말과 holidays.txt 의 날짜를 뺀다.
is_workday() {
  local d="$1"
  [ "$(date -d "$d" +%u)" -ge 6 ] && return 1
  grep -q -E "^$d([[:space:]]|\$)" "$STATE_DIR/holidays.txt" 2>/dev/null && return 1
  return 0
}

prev_workday() {
  local d="$1"
  while :; do
    d="$(date -d "$d -1 day" +%F)"
    is_workday "$d" && { echo "$d"; return; }
  done
}
