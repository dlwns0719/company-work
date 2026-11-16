---
name: GUIDE
type: router
version: 1.0
description: 슬래시 커맨드 라우터. 사용자 명령에 매핑된 가이드만 로드한다. 공통 규칙은 guides/GUIDE_CORE.md 에 있다.
scope: project
---

# GUIDE.md — company-work 진입점

> 이 파일은 **라우터**다. `CLAUDE.md` 가 이 파일을 읽게 하고, 이 파일이 공통 규칙과 skill 가이드 로드를 지시한다.

## 로드 원칙

```text
사용자 입력 → CLAUDE.md → GUIDE.md(이 파일) → guides/GUIDE_CORE.md → 해당 skill 가이드 하나 → 실행
```

슬래시 커맨드가 없으면 자연어로 가장 적합한 행을 추론한다. 맞는 행이 없으면 가이드 제약 없이 답한다.

## 슬래시 커맨드 정의

| 명령어 | 태스크 | 로드할 가이드 |
|---|---|---|
| `/day-start [날짜]` | **출근 브리핑** — 할 일 목록·직전 근무일 일지·미처리 입력·일정·메신저·자동 실행 기록을 읽어 오늘 할 일 3~5개를 제안한다. 답한 것만 todo 에 반영. `--auto`: 평일 아침 실행기가 `records/daily/YYYY-MM/<날짜>-brief.md` 에 저장 | `guides/day-start.md` |
| `/daily-log [날짜]` | **업무 일지** — 채팅·커밋 추출물과 그날 일정에서 후보를 뽑아 `records/daily/YYYY-MM/<날짜>-log.md` 에 고정 양식으로 기록. `--auto`: 평일 저녁 실행기가 후보 전부를 쓰고 todo 를 갱신(머리말 `auto:`·`reviewed: false`). 사람이 치면 검토 모드 | `guides/daily-log.md` |
| `/meeting-intake [전사] [회의명]` | **회의 전사 처리** — `records/inbox/transcripts/` 의 전사를 읽어 화자 대응·오류 보정 후 회의 폴더(`minutes.md` + `transcript.txt`)를 만든다. 이어지는 회의면 `meetings/series/` 의 회차 기록(누적 결정·이월 미결)을 갱신. 할 일 변경안·트래커 등록안은 확인 후 반영 | `guides/meeting-intake.md` |
| `/weekly-report [기간]` | **주간보고** — 그 주 일지·회의록·todo·대기열을 할 일 ID 로 묶어 `records/weekly/YYYY/YYYY-Www.md` 를 만든다. 지난 주 보고가 빠졌는지 먼저 확인. 트래커 반영·올리기는 확인 후 | `guides/weekly-report.md` |
| `/project-note <모드> [slug]` | **과제 폴더 정리** — 과제별 산출물을 `records/projects/<slug>/` 에 모으고 목차를 유지한다. `new`·`add`·`index`·`sweep`. 파일 이동은 확인 후 | `guides/project-note.md` |
| `/ops-check [기간]` | **자동 실행 점검** — `runs.tsv` 와 결과 파일을 대조해 빠진 날·실패·반복 경고를 찾고 고칠 방법을 제안한다. 읽기 전용 | `guides/ops-check.md` |

### 하루 흐름

```text
아침  수집(Windows) → /day-start --auto → 브리핑
낮    회의 → 전사가 inbox 로 들어옴 → /meeting-intake → 회의 폴더 · 회차 기록 · todo
      문서 작업 → /project-note add·index → 과제 폴더
저녁  수집(Windows) → /daily-log --auto → 일지 · todo
주 1회 /weekly-report → 주간보고    필요할 때 /ops-check
```

## 폴더 목록

| 폴더 | 용도 | 브랜치 |
|---|---|---|
| `guides/` | 스킬 가이드. `GUIDE_CORE.md` 는 공통 규칙 | main |
| `.claude/commands/` | 슬래시 커맨드 진입 파일 | main |
| `templates/` | 모든 양식. 스킬이 여기서 복사해 쓴다. 구조를 임의로 바꾸지 않는다 | main |
| `config/` | `company.example.env` 양식(main), `company.env` 실제 값(회사 브랜치) | 양식만 main |
| `scripts/run/` | 실행기 — Claude 를 띄워 브리핑·일지를 쓴다 (Linux, systemd 타이머) | main |
| `scripts/collect/windows/` | 수집기 — Outlook·Teams·전사·채팅을 `records/` 에 넣는다. AI 를 부르지 않는다 (Windows 작업 스케줄러) | main |
| `scripts/hooks/` | 보호 훅 — main 에 기록이 섞이거나 회사 브랜치가 밖으로 나가는 것을 막는다 | main |
| `records/` | 실제 업무 기록. 구조는 `records/README.md` | **회사 브랜치만** |

## 저장 규칙

- 새 산출물은 `records/README.md` 의 구조를 따른다. 정해진 자리에 맞지 않으면 `records/inbox/notes/` 에 두고 보고한다. 새 최상위 폴더를 만들지 않는다.
- 파일명은 `kebab-case`, 날짜는 `YYYY-MM-DD` 를 앞에 둔다. 한글·공백·대문자 파일명을 새로 만들지 않는다.
- 자동 모드는 그날 결과 파일과 todo 외에는 쓰지 않는다.

## 브랜치 규칙

- `main` 에는 공통 구조(스킬·양식·스크립트)만 둔다. 회사 이름·사람 이름·사내 경로·주소를 쓰지 않는다. 필요한 값은 `config/company.env` 에서 읽는다.
- 회사 브랜치에서 스킬을 고쳤으면 **기록과 한 커밋에 섞지 않는다.** main 으로는 그 커밋만 골라 옮긴다(cherry-pick). 머지하면 기록이 딸려 온다.
- 커밋·푸시는 사용자가 명시적으로 요청할 때만 한다.

## 규칙 우선순위

```text
guides/GUIDE_CORE.md  >  skill 가이드  >  에이전트 자체 판단
```

## Project Info

- **Stack**: bash, PowerShell 5.1(수집기), Python 3.10+ 표준 라이브러리만
- **Setup**: `bash scripts/setup.sh` → 회사 브랜치에서 `bash scripts/init-records.sh`
