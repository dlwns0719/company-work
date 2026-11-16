---
name: aidlc-apply
type: skill
version: 2.1
description: AWS Labs 의 AI-DLC v2 하네스를 대상 레포에 설치한다. 항상 새 브랜치를 만들고, 벤더 settings.json 에서 AWS Bedrock 강제(env·model·effortLevel)와 Bash 전체 허용만 삭제한 형태로 깐다. 훅은 추적되는 settings.json 에 둬 브랜치를 따라가게 한다. 기존 훅은 보존하고, 설치 후 시작 가이드를 남긴다.
---

# aidlc-apply — AI-DLC v2 하네스 설치

## 목적

[AI-DLC](https://github.com/awslabs/aidlc-workflows) v2 하네스를 대상 레포에 깐다.
설치하면 `/aidlc <설명>` 으로 32단계 워크플로(INITIALIZATION·IDEATION·INCEPTION·CONSTRUCTION·OPERATION)를
돌릴 수 있다. 단계마다 승인 게이트에서 멈춘다.

이 스킬은 **설치까지만** 한다. 워크플로 실행은 대상 레포에서 새 세션을 열어 진행한다.

### 계보 주의

이 레포는 줄기가 둘이다. **`main` 은 1.x**(마크다운 규칙 `aidlc-rules/`)이고 후속이 끊겼다.
**태그 `v2.x` 는 `v2` 브랜치**에서 나오며 이쪽이 현행이다. 이 스킬은 **v2 만** 다룬다.
`main` 을 받으면 `dist/` 가 없으므로 Step 4 의 구조 검사에서 걸러진다.

### 원칙 — 커스터마이징은 삭제만

**벤더 파일에 무언가를 더하지 않는다.** 위험한 항목을 지우기만 한다. 나중에 원본과 대조하거나
팀에 설명할 때, "이 4개를 지웠다" 로 끝나야 한다. 예외는 셋뿐이다 —
**기존 훅을 잃지 않기 위한 이어붙이기**, **삭제로 거짓이 된 서술의 정정**(Step 6),
그리고 **기존 statusLine 을 잃지 않기 위한 래퍼**(Step 5-(6), 선택).

### 지키는 것 넷

1. **항상 새 브랜치에 깐다.** 현재 브랜치가 공유 브랜치일 수 있다.
2. **AWS 의존성을 제거한다.** 배포본 `settings.json` 은 `CLAUDE_CODE_USE_BEDROCK=1` 로
   **모델 제공자를 Bedrock 으로 강제**하고 모델·effort 를 고정한다(README:92·188 에 고지된 설계다).
   그대로 두면 그 레포의 모든 세션이 Bedrock 으로 나가고 자격증명이 없으면 동작하지 않는다.
   **제거해도 훅·스킬·에이전트·스테이지는 전부 정상 동작한다** — 엔진이 하는 일은 파일 입출력이고,
   AWS 참조는 상태줄의 모델명 접두어 제거 1건뿐이다.
3. **훅은 추적되는 `settings.json` 에 둔다.** `settings.local.json` 은 git 이 무시하므로
   **브랜치를 넘어 남는다.** 거기에 훅을 등록하면 하네스 파일이 없는 브랜치에서도 등록만 살아남아
   매 세션 실패한다. `settings.json` 에 두면 브랜치 전환만으로 하네스 전체가 켜지고 꺼진다.
4. **기존 `settings.json`·`CLAUDE.md` 를 덮지 않는다.** 병합·덧붙인다.

## 입력

`$ARGUMENTS` = `[대상-레포-경로] [버전태그]`.

- 경로가 없으면 사용자에게 묻는다.
- 버전태그를 생략하면 **최신 태그를 조회해 쓴다**.
- 브랜치·범위는 인자로 받지 않는다. **Step 3 에서 항상 묻는다.**

## Step

### Step 1 — 대상 확인

```bash
git -C <대상> rev-parse --is-inside-work-tree
git -C <대상> branch --show-current
git -C <대상> status --short
ls <대상>/.claude <대상>/aidlc <대상>/CLAUDE.md 2>/dev/null
```

- git 레포가 아니면 중단한다.
- `<대상>/aidlc/` 또는 `.claude/skills/aidlc/` 가 있으면 **이미 설치됨**으로 보고하고 중단한다.
- 기존 `.claude/settings.json`·`hooks/`·`skills/` 를 **읽어 목록을 보고한다.** Step 5 에서 보존할 대상이다.
- 대상 레포에 CI 게이트(인덱스 검사 등)가 있으면 확인해 둔다. 커밋 전에 통과해야 한다.

### Step 2 — bun 확인 (비대화형 PATH 까지)

v2 는 훅 11개와 도구 26개가 TypeScript 다. **bun 없이는 하네스가 동작하지 않는다.**

**`command -v bun` 만으로는 부족하다.** Claude Code 는 훅을 `/bin/sh`(대개 dash)로 비대화형 실행하는데,
그 셸은 `~/.bashrc` 를 읽지 않는다. bun 설치기는 PATH 를 `~/.bashrc` 에 넣으므로
**대화형 터미널에서는 보이고 훅에서는 안 보이는 상태**가 흔하다. 반드시 아래로 검사한다.

```bash
/bin/sh -c 'command -v bun' || echo "비대화형 셸에서 bun 안 보임"
```

- **미설치**면 설치 명령을 안내하고 **사용자 확인을 받는다**(머신 전역이라 브랜치로 되돌릴 수 없다).
  ```bash
  curl -fsSL https://bun.sh/install | bash
  ```
- **설치됐는데 비대화형에서 안 보이면**, PATH 에 이미 있고 쓰기 가능한 디렉터리에 심링크한다.
  ```bash
  /bin/sh -c 'echo $PATH' | tr ':' '\n'          # 후보 확인 (보통 ~/.local/bin)
  ln -sf ~/.bun/bin/bun ~/.local/bin/bun
  /bin/sh -c 'command -v bun && bun --version'   # 재확인
  ```

사용자가 설치를 원치 않으면 중단한다. 파일만 깔면 매 프롬프트·세션·편집마다 훅이 실패한다.

### Step 3 — 브랜치·범위 확정 (항상 묻는다)

**인자로 받지 않는다. 매 실행마다 확인받는다.**

1. **기준 브랜치** — 어디에서 갈라낼지. 기본값은 현재 브랜치.
   ```bash
   git -C <대상> branch -a --format='%(refname:short)' | head -20
   ```
2. **새 브랜치 이름** — `<타입>/aidlc-<대상>` 형태.
   - 접두어는 대상 레포의 브랜치 규칙을 따른다(conventional commit 타입과 정렬하는 레포가 많다).
   - **무엇을 개발하는지를 이름에 넣는다.** 예: `feat/aidlc-run-diagnoser`
3. **적용 범위** — 어느 대상에 적용할지(예: `run_diagnoser`). Step 6·7 에 넣는다.
   기존 코드가 있는 레포에서 범위를 안 좁히면 Reverse Engineering(2.1) 이 전 패키지를 문서화한다.

```bash
git -C <대상> checkout -b <새브랜치> <기준브랜치>
```

미커밋 변경은 새 브랜치로 따라온다(사라지지 않는다). 그 사실을 알린다.

### Step 4 — 버전 확정 후 받기

```bash
TAG=$(git ls-remote --tags --refs --sort=-v:refname \
  https://github.com/awslabs/aidlc-workflows.git 'v*' | head -1 | sed 's|.*refs/tags/||')

CACHE=/tmp/aidlc-$TAG
[ -d "$CACHE" ] || git clone --depth 1 --branch "$TAG" \
  https://github.com/awslabs/aidlc-workflows.git "$CACHE"
```

확정 태그를 1줄로 보고한다. **구조를 검사한다** — `$CACHE/dist/claude/` 가 없으면 v2 가 아니므로
중단하고 보고한다.

조회가 실패하면 `/tmp/aidlc-v*` 캐시 중 가장 높은 버전을 쓰고 **캐시본을 썼다는 사실을 보고한다.**
캐시도 없으면 중단한다.

### Step 5 — 복사 + settings 무해화

**(1) 파일 복사**

```bash
cp -R "$CACHE/dist/claude/.claude/"* <대상>/.claude/
cp -R "$CACHE/dist/claude/aidlc" <대상>/aidlc
```

이 명령은 **기존 `settings.json` 을 덮는다.** 덮인 것을 확인하고 즉시 복구한 뒤 (2) 로 간다.

```bash
git -C <대상> checkout -- .claude/settings.json    # 추적 파일이면 이것으로 복구
```

**(2) 무해화 — 벤더 `settings.json` 에서 삭제만 한다**

| 삭제 | 이유 |
|---|---|
| `env` 블록 전체 | `CLAUDE_CODE_USE_BEDROCK`·`AWS_REGION`·모델 4종 핀. 제공자·요금이 바뀐다 |
| `model` | 프로젝트 모델 고정 |
| `effortLevel` | 프로젝트 effort 고정 |
| `permissions.allow` 의 `"Bash"` | 인자 없는 전체 허용. 승인 프롬프트가 사라진다 |

**나머지는 원본 그대로 둔다** — `hooks` 11개·`statusLine`·`companyAnnouncements`·
`permissions.allow` 의 나머지(`Bash(bun "$CLAUDE_PROJECT_DIR/.claude/tools/"*)` 는 도구 실행에 필요하다).
훅 명령에 조건을 씌우거나 항목을 추가하지 않는다.

`env` 를 지우면 `AWS_AIDLC_DEFAULT_SCOPE` 도 사라져 스코프가 자동 판정으로 돌아간다. 의도된 결과다.

**(3) 기존 훅 이어붙이기** — Step 1 에서 확인한 기존 훅을 해당 이벤트 배열 **뒤에 추가**한다.
기존 항목의 필드(`shell`·`timeout`·`statusMessage`)를 그대로 보존한다. 기존 `permissions` 가
있으면 합집합으로 둔다.

**(4) 검증**

```bash
python3 -c "
import json,pathlib
j = json.loads(pathlib.Path('<대상>/.claude/settings.json').read_text())
a = j.get('permissions',{}).get('allow',[])
print('잔존 키:', [k for k in ('env','model','effortLevel') if k in j] or '없음')
print('인자없는 Bash:', 'Bash' in a)
print('훅:', [h['command'].split('/')[-1] for ev in j['hooks'].values() for g in ev for h in g['hooks']])"
```

단순 `grep '\"Bash\"'` 는 훅의 `\"matcher\": \"Bash\"` 를 오탐하므로 쓰지 않는다.
훅 목록에 **기존 훅이 남아 있는지** Step 1 기록과 대조한다.

**(5) 실제 실행 확인** — 훅과 같은 조건(비대화형 셸)에서 돌려본다.

```bash
/bin/sh -c "cd <대상> && CLAUDE_PROJECT_DIR=<대상> bun .claude/hooks/aidlc-statusline.ts" </dev/null
```

**(6) statusLine 충돌 처리 (선택)**

벤더 `settings.json` 은 `statusLine` 을 자기 것으로 지정한다. **프로젝트 설정이 전역을 이기므로**,
사용자가 전역(`~/.claude/settings.json`)에 상태줄을 쓰고 있으면 그 브랜치에서 가려진다.
모델·경로·컨텍스트 잔량을 상시 보는 사람에게는 손실이다.

```bash
python3 -c "
import json,pathlib
p=pathlib.Path.home()/'.claude/settings.json'
print(json.loads(p.read_text()).get('statusLine','없음') if p.exists() else '없음')"
```

기존 상태줄이 있으면 **가릴지 합칠지 사용자에게 묻는다.** 합치기로 하면 래퍼를 하나 둔다.
둘 다 stdin 으로 같은 JSON 을 받아 한 줄을 내므로 입력을 양쪽에 흘려 이어붙이면 된다.

```bash
cat > <대상>/.claude/aidlc-statusline-wrapper.sh <<'SH'
#!/usr/bin/env bash
input=$(cat)
mine=$(printf '%s' "$input" | bash "$HOME/.claude/statusline-command.sh" 2>/dev/null)
aidlc=$(printf '%s' "$input" | bun "$CLAUDE_PROJECT_DIR/.claude/hooks/aidlc-statusline.ts" 2>/dev/null)
if [ -n "$aidlc" ]; then printf '%s | %s\n' "$mine" "$aidlc"; else printf '%s\n' "$mine"; fi
SH
chmod +x <대상>/.claude/aidlc-statusline-wrapper.sh
```

`settings.json` 의 `statusLine.command` 를 이 래퍼로 바꾼다. 벤더의 `aidlc-statusline.ts` 는
건드리지 않는다 — 되돌리기는 그 한 줄을 원복하면 끝이다.

**렌더 시간이 늘어난다**(bun 기동분, 실측 47ms → 80ms). 값을 재서 사용자에게 보고한다.
합친 뒤 실제 입력으로 출력과 소요시간을 확인한다.

### Step 6 — CLAUDE.md 처리

**(1) 루트 `CLAUDE.md` 맨 끝에 덧붙인다.** 기존 내용은 한 글자도 고치지 않는다.
파일이 없으면 이 내용만으로 새로 만든다.

```markdown
## AI-DLC v2 하네스 (<태그>, 시험 적용)

`/aidlc <설명>` 으로 워크플로를 시작한다. **사용법은 `aidlc-start.md` 를 읽는다.**

- 적용 범위: <Step 3 의 답> 에 한정한다.
- **이 파일 위쪽의 기존 규칙이 우선한다.** 충돌하면 위쪽을 따른다.
- 설치본은 AWS Bedrock 강제(`env`·`model`·`effortLevel`)와 `Bash` 전체 허용을 제거한 형태다.
```

우선순위 줄은 빼지 않는다. AI-DLC 는 자기 절차를 최우선으로 두므로, 명시하지 않으면
대상 레포의 기존 규칙(핸드오프 의무·브랜치 전략 등)을 밀어낸다.

**(2) 배포본 `.claude/CLAUDE.md` 의 거짓이 된 서술을 정정한다.**
이 파일은 프로젝트 메모리로 **매 세션 읽힌다.** 무해화로 사실이 아니게 된 서술을 그대로 두면
다음 세션이 잘못된 전제로 움직인다. 최소 아래 둘을 확인해 고친다.

- "AWS Bedrock 접근이 필요하다" → 이 설치본에는 해당 없음을 적는다.
- "`settings.json` 이 Bash 를 사전 승인한다" → 인자 없는 `Bash` 를 제거했음을 적는다.

플레이스홀더 제목(`# Project Name`)도 실제 이름으로 채운다.

### Step 7 — 시작 가이드 생성

대상 레포 루트에 `aidlc-start.md` 를 만든다. **다른 세션에서 이 파일 하나만 읽으면
시작할 수 있어야 한다.** 아래를 채운다.

- 깔린 태그·적용 범위·설치 브랜치·bun 경로
- 시작 명령 — `/aidlc --doctor` 후 `/aidlc <설명>`
- 자주 쓰는 것 — `--status` · `--stage <id>` · `--phase <name>` · `--scope <name>` · `--help`
- 32단계 5국면 표와 스코프 표(배포본 `settings.json` 의 `companyAnnouncements` 에 원문이 있다)
- 산출물 위치(`aidlc-docs/`)
- **무해화 내역** — 무엇을 왜 지웠는지. 원본 대조·팀 설명에 쓴다
- 팀 영향 — 이 브랜치를 공유 브랜치로 머지하면 팀원도 bun 이 필요해진다
- 되돌리는 법

브라운필드면 기존 아키텍처 문서 경로를 찾아 **Reverse Engineering(2.1) 을 건너뛰라는 문장**을
시작 명령 예시에 넣는다.

### Step 8 — 커밋 안내와 결과 보고

**커밋해야 브랜치 격리가 완성된다.** 설치물이 untracked 로 남으면 브랜치를 바꿔도 파일이 남는다.
Step 1 에서 확인한 CI 게이트를 먼저 통과시키고, **대상 레포의 커밋 메시지 관례**(언어·형식)를 따른다.
메시지 본문에 **무엇을 왜 지웠는지** 남긴다 — 나중에 팀에 보여줄 근거가 이 커밋이다.

무관한 미커밋 변경은 **스테이징에서 제외**한다. 커밋은 하되 **푸시하지 않는다.**

```text
설치 완료 — <대상> · 브랜치 <새브랜치> · AI-DLC <태그> · 범위 <범위>
무해화(삭제만): env(Bedrock 강제) · model · effortLevel · Bash 전체 허용
보존: <Step 1 에서 확인한 기존 훅·스킬>

주의 2가지
1. aidlc-docs/audit.md 에 대화 원문이 요약 없이 쌓인다. 비밀번호·API 키를 대화에 넣지 마라.
   커밋 전에 훑어라. 커밋하지 않으려면 .gitignore 에 추가한다.
2. 이 브랜치를 공유 브랜치로 머지하면 팀원도 bun 이 필요해진다. 머지 전에 합의한다.

다음: cd <대상> && claude → aidlc-start.md 를 읽는다
```

## 보고 전

`guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다.

## 금지

- **`env`·`model`·`effortLevel` 을 그대로 두는 것 금지.** 제공자·요금·모델이 바뀐다.
- `permissions.allow` 에 인자 없는 `"Bash"` 를 남기는 것 금지.
- **훅을 `settings.local.json` 에 등록하는 것 금지.** git 이 무시해 브랜치를 넘어 남는다.
- **벤더 파일에 항목을 추가하는 것 금지.** 삭제만 한다. 예외는 기존 훅 이어붙이기와
  거짓이 된 서술 정정뿐이다.
- 현재 브랜치에 그대로 설치 금지. 브랜치·범위를 묻지 않고 진행 금지.
- 기존 `settings.json`·`CLAUDE.md` 덮어쓰기 금지.
- 태그 없이 기본 브랜치를 받는 것 금지. `main` 은 1.x 라 구조가 다르다.
- `command -v bun` 만으로 bun 확인을 끝내는 것 금지. 비대화형 셸로 검사한다.
- 대상 레포의 코드·기존 문서 수정 금지. 워크플로 실행 금지.

## 되돌리기

브랜치를 버리는 것이 가장 빠르다. 설치물이 커밋돼 있으면 브랜치 전환만으로 사라진다.

```bash
git checkout <기준브랜치>
git branch -D <새브랜치>
```

파일만 지우려면 — `.claude/` 하위 `aidlc*` 전부(`skills/aidlc*`·`agents/aidlc-*`·
`hooks/aidlc-*`·`tools/`·`aidlc-common/`·`knowledge/`·`scopes/`·`sensors/`·
`rules/aidlc.md`·`CLAUDE.md`), 루트 `aidlc/`·`aidlc-start.md`,
루트 `CLAUDE.md` 의 `## AI-DLC v2 하네스` 블록, `settings.json` 에 추가된 aidlc 훅.

`aidlc-docs/` 는 워크플로 산출물이므로 사용자 확인 없이 지우지 않는다.
bun 과 심링크는 머신 전역이라 이 스킬이 지우지 않는다.
