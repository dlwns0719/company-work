---
description: 출근 브리핑. 할 일 목록·직전 근무일 일지·미처리 입력·일정·메신저·자동 실행 기록을 읽어 오늘 할 일을 제안하고, 사용자 답에 따라 할 일 목록을 갱신한다.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/day-start.md` 를 Read 로 읽는다 (skill).
4. day-start.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
   - 수집 자료가 없으면 `자료 없음` 1줄로 넘어간다. 이 스킬은 수집하지 않는다
   - **답 없으면 todo 변경 금지**
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다. `--auto` 로 불렸으면 가이드의 자동 모드 절을 따르고 Self-Check 를 생략한다.

## 인자

`[날짜]` (선택, `YYYY-MM-DD`). 없으면 오늘. `--auto` 는 실행기가 붙인다.

사용자가 전달한 인자:

```text
$ARGUMENTS
```
