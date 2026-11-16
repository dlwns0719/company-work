#!/usr/bin/env bash
# 레포를 받은 뒤 한 번 실행한다. 보호 훅을 켠다.
#
# 사용: bash scripts/setup.sh [회사 기록을 올려도 되는 remote 이름]
#
# - pre-commit: main 브랜치에 records/ 내용이나 config/company.env 가 커밋되는 것을 막는다.
# - pre-push:   main 이 아닌 브랜치(회사 기록)가 허용하지 않은 remote 로 나가는 것을 막는다.
#   회사가 허용한 저장소가 있으면 그 remote 이름을 인자로 준다. 주지 않으면 회사 브랜치는 어디로도 push 되지 않는다.
set -euo pipefail

cd "$(dirname "$0")/.."
git config core.hooksPath scripts/hooks
chmod +x scripts/hooks/* scripts/run/*.sh scripts/*.sh 2>/dev/null || true
if [ -n "${1:-}" ]; then
  git config work.recordsRemote "$1"
  echo "회사 브랜치 push 허용 remote: $1"
else
  echo "회사 브랜치는 push 되지 않는다 (허용 remote 없음)"
fi
echo "보호 훅 켜짐: $(git config core.hooksPath)"
