---
description: 자동 실행 점검. runs.tsv 와 결과 파일을 대조해 빠진 날·실패·반복 경고를 찾고 고칠 방법을 제안한다. 읽기 전용.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/ops-check.md` 를 Read 로 읽는다 (skill).
4. ops-check.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
   - 읽기 전용이다. 기록·설정·타이머를 고치지 않는다
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다. `--auto` 로 불렸으면 가이드의 자동 모드 절을 따르고 Self-Check 를 생략한다.

## 인자

`[기간]` (선택). 없으면 최근 근무일 10일. `YYYY-MM-DD~YYYY-MM-DD` 또는 `Nd`.

사용자가 전달한 인자:

```text
$ARGUMENTS
```
