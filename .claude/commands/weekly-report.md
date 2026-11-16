---
description: 주간보고. 그 주 일지·회의록·할 일 목록·트래커 대기열을 모아 records/weekly/ 에 주간보고를 만들고, 트래커 반영과 올리기는 확인 후 처리한다.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/weekly-report.md` 를 Read 로 읽는다 (skill).
4. weekly-report.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
   - 기록에 없는 성과를 지어내지 않는다. 양식의 섹션 이름을 바꾸지 않는다
   - **확인 전 트래커 쓰기·올리기 금지**
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다. `--auto` 로 불렸으면 가이드의 자동 모드 절을 따르고 Self-Check 를 생략한다.

## 인자

`[기간]` (선택). 없으면 이번 주 월요일 ~ 오늘. `YYYY-MM-DD~YYYY-MM-DD` 형식도 받는다.

사용자가 전달한 인자:

```text
$ARGUMENTS
```
