#!/usr/bin/env bash
# 회사 브랜치에서 records/ 뼈대를 만든다. 이미 있는 파일은 건드리지 않는다.
#
# 사용: bash scripts/init-records.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

branch="$(git symbolic-ref --short -q HEAD || true)"
if [ "$branch" = "main" ]; then
  echo "main 브랜치에는 기록을 두지 않는다. 회사 브랜치를 먼저 만든다: git switch -c <회사이름>" >&2
  exit 1
fi

R=records
mkdir -p "$R"/{inbox/transcripts,inbox/notes,daily,meetings/series,weekly,projects,team} \
         "$R"/_system/{sources/chat,sources/outlook,sources/teams,state,queue,logs}

copy_once() {  # copy_once <양식> <대상>
  if [ -e "$2" ]; then echo "있음: $2"; else cp "$1" "$2"; echo "생성: $2"; fi
}
copy_once templates/todo.md            "$R/todo.md"
copy_once templates/meetings-state.md  "$R/_system/state/meetings.md"
copy_once templates/glossary.md        "$R/_system/state/glossary.md"
copy_once templates/tracker-queue.md   "$R/_system/queue/tracker-pending.md"
[ -e "$R/_system/state/holidays.txt" ] || { printf '# 자동 실행을 건너뛸 날짜. 한 줄에 YYYY-MM-DD 하나, 뒤에 공백을 두고 설명을 적을 수 있다.\n' > "$R/_system/state/holidays.txt"; echo "생성: $R/_system/state/holidays.txt"; }
[ -e "$R/_system/state/runs.tsv" ] || { : > "$R/_system/state/runs.tsv"; echo "생성: $R/_system/state/runs.tsv"; }

sed -i "s/YYYY-MM-DD/$(date +%F)/" "$R/todo.md" 2>/dev/null || true
[ -e config/company.env ] || echo "다음: cp config/company.example.env config/company.env 후 값을 채운다"
