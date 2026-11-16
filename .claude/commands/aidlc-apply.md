---
description: AI-DLC v2 하네스(awslabs/aidlc-workflows)를 대상 레포에 설치한다. 최신 태그 고정, 새 브랜치, 커스터마이징은 삭제만.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/aidlc-apply.md` 를 Read 로 읽는다 (skill).
4. aidlc-apply.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다.

## 인자

`[레포경로] [태그]` (모두 선택).

사용자가 전달한 인자:

```text
$ARGUMENTS
```
