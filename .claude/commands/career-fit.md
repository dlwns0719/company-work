---
description: 현재·예정 업무를 커리어 패스 기준(career/career-path.md)으로 채점. 점수 + 근거 + 갭/액션 산출. 인자로 업무 설명 또는 업무 MD 파일 경로를 받는다.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/career-fit.md` 를 Read 로 읽는다 (skill).
4. career-fit.md 의 Step 1~6 을 **순서대로** 실행한다.
   - Step 1: 기준 문서 `career/career-path.md` Read (§5 가중치, §6 임계값, §7 입력, §8 출력, §9~§13, §15)
   - Step 2: 사용자 업무 설명을 §7 9항목으로 정규화 (누락은 "정보 부족", 핵심 누락 시 1회 보충 질문)
   - Step 3: §5 7개 축 채점 — 축별 점수 + 업무 설명 인용 근거. 근거 없는 가점·미래 가능성 가점 금지
   - Step 4: 총점 합산 + §6 구간 판정
   - Step 5: §10/§9 강화 액션 2~4개, §13 보완 역량 연결, 이력서 문장, §11 주의점
   - Step 6: §8 출력 양식 그대로 작성 (축별 근거 칸 필수, 점수는 획득/만점)
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다.

## 인자

이 스킬은 평가할 업무 설명을 인자로 받는다.

- **자유 서술** (`/career-fit 사내 RAG 챗봇에 Tool Calling 붙이는 업무`) → 서술을 §7 양식으로 매핑해 채점
- **§7 양식 텍스트** → 그대로 채점
- **MD 파일 경로** (`/career-fit ~/Downloads/task.md`) → 파일을 Read 후 채점
- **인자 없음** → §7 입력 양식을 보여주고 업무 설명을 요청한 뒤 종료

사용자가 전달한 인자:

```text
$ARGUMENTS
```
