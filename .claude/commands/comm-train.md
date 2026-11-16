---
description: 커뮤니케이션 직렬화 약점(핵심 후치·전제 후행·지시대명사·다중요구·듣기 재프레이밍)을 의도적 연습 루프로 교정. 코치가 대신 쓰지 않고 사용자가 직접 산출 → 채점 → 로깅. 기준은 comm-train/curriculum.md
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/comm-train.md` 를 Read 로 읽는다 (skill).
4. comm-train.md 의 Step 1~5 를 **순서대로** 실행한다.
   - Step 1: 기준 `comm-train/curriculum.md` + 상태 `comm-train/progress-log.md` Read → 현재 레벨·연속 합격·반복 약점 파악
   - Step 2: 모드 분기 (status / crutch / real / start·drill) — curriculum.md §7
   - Step 3: 훈련 루프 (제시 → 사용자 직접 산출 대기 → 채점 → 분기). **모범답안 선제공 금지** (curriculum.md §5)
   - Step 4: 결과를 progress-log.md 하단에 append (curriculum.md §6 양식), 현재 레벨 갱신
   - Step 5: 현재 레벨·연속 합격·다음 권장 1~2줄 안내
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다.

## 인자

`[모드] [내용]` 형태로 받는다. 모드 없으면 `start`.

- `/comm-train` 또는 `/comm-train start` → 현재 레벨 드릴 세션
- `/comm-train drill` → 현재 레벨 드릴 강제 시작
- `/comm-train real <보낼 메시지 초안>` → 실제 메시지를 소재로 진단·자가수정·채점
- `/comm-train status` → 진행 곡선·반복 약점 요약 (드릴 안 함)
- `/comm-train crutch <초안>` → 목발 모드(즉시 재작성, 로깅 안 함, 남용 경고)

사용자가 전달한 인자:

```text
$ARGUMENTS
```
