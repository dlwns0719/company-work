---
description: 회의 전사(STT)를 받아 화자 대응·오류 보정 후 회의 폴더에 회의록을 쓰고, 이어지는 회의면 회차 기록을 갱신하고, 할 일 변경안과 트래커 등록안을 만든다. 반영은 확인 후에만.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/meeting-intake.md` 를 Read 로 읽는다 (skill).
4. meeting-intake.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
   - 확신도 낮은 화자를 이름으로 단정하지 않는다
   - **지정 전 todo·대기열 변경 금지**. 회의록·원문을 외부에 올리지 않는다
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다. `--auto` 로 불렸으면 가이드의 자동 모드 절을 따르고 Self-Check 를 생략한다.

## 인자

`[전사 파일 경로] [회의명]` (모두 선택). 없으면 `records/inbox/transcripts/` 에서 고른다.

사용자가 전달한 인자:

```text
$ARGUMENTS
```
