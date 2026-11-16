#!/usr/bin/env bash
# 출근 브리핑·퇴근 일지를 사람 없이 실행한다 (systemd 사용자 타이머가 부른다).
#
# 사용: scripts/run/work-auto.sh <day-start|daily-log> [YYYY-MM-DD]
#
# - 주말·records/_system/state/holidays.txt 날짜면 아무것도 하지 않는다 (날짜 인자를 주면 이 검사를 건너뛴다).
# - 결과 파일이 이미 있으면 건너뛴다. 다시 만들려면 그 파일을 옮기거나 지운다.
# - Claude 를 띄우기 전에 이 PC 의 채팅·커밋을 고정 스크립트로 뽑아 둔다. 일정·메일·메신저는 Windows 수집기
#   (scripts/collect/windows/collect.ps1)가 같은 폴더에 넣어 둔 것을 읽는다. 없어도 멈추지 않고 runs.tsv 에 남긴다.
# - claude -p 를 사용자 설정 없이(--setting-sources project) 띄우고, 쓸 수 있는 파일을 그날 결과 파일로 좁힌다.
# - 모든 실행은 records/_system/state/runs.tsv 에 한 줄씩 남는다. 로그인 만료 경고처럼 성공했지만 손봐야 할 것도 남긴다.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
. "$REPO/scripts/lib/config.sh"

SKILL="${1:-}"
DAY="${2:-}"
FORCE=0
[ -n "$DAY" ] && FORCE=1
DAY="${DAY:-$(date +%F)}"
MARKER="[work-auto]"
HOST="$(hostname)"

notify() {
  command -v notify-send >/dev/null && notify-send -a work "$1" "$2" || true
}

case "$SKILL" in
  day-start)
    KIND="brief"; TITLE="출근 브리핑"
    EXTRA_TOOLS=()
    [ -n "${TRACKER_GET_CMD:-}" ] && EXTRA_TOOLS+=("Bash($TRACKER_GET_CMD:*)")
    ;;
  daily-log)
    KIND="log"; TITLE="일지"
    EXTRA_TOOLS=("Edit(./records/todo.md)")
    ;;
  *)
    echo "사용: $0 <day-start|daily-log> [YYYY-MM-DD]" >&2
    exit 2
    ;;
esac

if ! date -d "$DAY" +%F >/dev/null 2>&1 || [ "${#DAY}" -ne 10 ]; then
  echo "날짜 형식 오류: $DAY (YYYY-MM-DD)" >&2
  exit 2
fi

if [ "$FORCE" -eq 0 ] && ! is_workday "$DAY"; then
  echo "$DAY 주말·휴무, 건너뜀"
  exit 0
fi

MONTH="${DAY:0:7}"
OUT_REL="records/daily/$MONTH/$DAY-$KIND.md"
if [ -e "$REPO/$OUT_REL" ]; then
  echo "$OUT_REL 이미 있음, 건너뜀"
  record_run "$SKILL" skip "$OUT_REL 이미 있음"
  exit 0
fi

LOG_DIR="$RECORDS/_system/logs/$MONTH"
SRC="$RECORDS/_system/sources"
mkdir -p "$REPO/records/daily/$MONTH" "$LOG_DIR" "$SRC/chat"
LOG="$LOG_DIR/$DAY-$SKILL.log"
ERR="$LOG_DIR/$DAY-$SKILL.err.log"
PREP="$LOG_DIR/$DAY-$SKILL.prep.log"
: > "$PREP"

# 1. 재료 준비 (실패해도 계속)
# 일지는 그날, 브리핑은 직전 근무일 채팅을 뽑는다(전날 일지를 쓴 뒤의 활동을 보기 위해서다).
if [ "$SKILL" = "day-start" ]; then EXTRACT_DAY="$(prev_workday "$DAY")"; else EXTRACT_DAY="$DAY"; fi
PY="$(command -v python3 || command -v python || echo python3)"
if "$PY" -I "$REPO/scripts/chatlog_extract.py" "$EXTRACT_DAY" > "$SRC/chat/$EXTRACT_DAY-$HOST.md" 2>>"$PREP"; then
  echo "[chatlog_extract $EXTRACT_DAY] 종료 코드 0" >> "$PREP"
else
  echo "[chatlog_extract $EXTRACT_DAY] 실패" >> "$PREP"
  record_run "$SKILL" warn "채팅 추출 실패 ($EXTRACT_DAY)"
fi

# Windows 수집기가 넣어 줬어야 할 자료가 있는지 본다. 없으면 브리핑에 "자료 없음" 으로 나온다.
MISSING=""
[ "${COLLECT_OUTLOOK:-0}" = "1" ] && [ ! -e "$SRC/outlook/$DAY.md" ] && MISSING="$MISSING outlook"
[ "$SKILL" = "day-start" ] && [ "${COLLECT_TEAMS:-0}" = "1" ] && [ ! -e "$SRC/teams/$DAY-brief.md" ] && MISSING="$MISSING teams"
if [ -n "$MISSING" ]; then
  echo "[수집 자료 없음]$MISSING" >> "$PREP"
  record_run "$SKILL" warn "수집 자료 없음:$MISSING (Windows 수집기 확인)"
fi

# 2. Claude 실행
ALLOWED=("Read" "Glob" "Grep" "Bash(date:*)" "Edit(./$OUT_REL)" "${EXTRA_TOOLS[@]}")
DENIED=("Read(./.env)" "Read(./.env.*)" "Agent" "WebFetch" "WebSearch" "NotebookEdit")
ARGS=(-p "/$SKILL $DAY --auto --at \"$(date '+%F %H:%M')\" $MARKER"
      --setting-sources project --permission-mode dontAsk
      --allowedTools "${ALLOWED[@]}" --disallowedTools "${DENIED[@]}")
[ -n "${CLAUDE_MODEL:-}" ] && ARGS+=(--model "$CLAUDE_MODEL")

cd "$REPO" || exit 1
timeout "${RUN_TIMEOUT_MIN}m" "$CLAUDE_BIN" "${ARGS[@]}" >"$LOG" 2>"$ERR"
RC=$?

# 성공해도 손봐야 할 경고(로그인 만료 예고, 모델 이름 오류 등)는 따로 남긴다.
WARN="$(grep -i -m1 -E 'sign-in|auth login|unrecognized_model|rate.?limit|expired' "$ERR" 2>/dev/null | cut -c1-160)"
[ -n "$WARN" ] && record_run "$SKILL" warn "$WARN"

if [ "$RC" -eq 0 ] && [ -e "$REPO/$OUT_REL" ]; then
  # 요약 줄은 'n · n · n' 형식이다. 모델이 뒤에 다른 말을 덧붙여도 그 줄을 고른다.
  SUMMARY="$(grep ' · ' "$LOG" | tail -n 1)"
  [ -z "$SUMMARY" ] && SUMMARY="$(grep -v '^[[:space:]]*$' "$LOG" | tail -n 1)"
  SUMMARY="$(printf '%s' "$SUMMARY" | cut -c1-200)"
  record_run "$SKILL" ok "$SUMMARY"
  notify "$TITLE 준비됨 ($DAY)" "$SUMMARY
$OUT_REL"
  exit 0
fi

if [ "$RC" -eq 124 ]; then REASON="시간 초과 (${RUN_TIMEOUT_MIN}분)"; else REASON="종료 코드 $RC"; fi
record_run "$SKILL" fail "$REASON"
notify "$TITLE 실패 ($DAY)" "$REASON. 로그: records/_system/logs/$MONTH/$DAY-$SKILL.log"
exit 1
