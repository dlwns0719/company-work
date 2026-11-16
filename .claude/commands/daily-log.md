---
description: 업무 일지. 채팅·커밋 추출물과 그날 일정에서 후보를 뽑아 records/daily/ 에 고정 양식으로 기록한다. 자동 일지가 있으면 검토 모드로 돈다.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/daily-log.md` 를 Read 로 읽는다 (skill).
4. daily-log.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
   - 대화형에서는 **사용자 지정 전 기록 금지**. 기존 일지는 이어쓰기만 한다
   - 양식은 `templates/daily-log.md` 그대로 쓴다
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다. `--auto` 로 불렸으면 가이드의 자동 모드 절을 따르고 Self-Check 를 생략한다.

## 인자

`[날짜]` (선택, `YYYY-MM-DD`). 없으면 오늘. `--auto`·`--at` 은 실행기가 붙인다.

사용자가 전달한 인자:

```text
$ARGUMENTS
```
