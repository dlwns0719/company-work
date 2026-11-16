---
description: 레퍼런스 에이전트 플랫폼 스타일 에이전트 아키텍처 하네스. 새 에이전트를 설계(design)·골격(scaffold)·검토(review)할 때 7원칙(계약우선·얇은agent/무거운domain·단방향의존·라우터가 횡단관심사·결정론우선·포트&어댑터·조합확장)에 맞춰 안내한다. 인자로 모드와 대상을 받는다.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/agent-arch.md` 를 Read 로 읽는다 (skill 본문 — 7원칙·계층지도·Step 레시피·결정 포인트).
4. agent-arch.md 에 따라 모드별로 실행한다.
   - `design <아이디어>` → 계층 배치 + 포트 목록 + 의존방향 검증 + 열린 결정 산출
   - `scaffold <이름>` → 파일 트리 + Step별 체크리스트 + 라우터/main.py 배선 요지
   - `review <경로|설명>` → 7원칙 각각 통과/위반 + 근거 + 개선안 (레드플래그 점검)
5. 파일 생성/수정은 사용자 승인 후에만. 기본은 설계·점검 산출.

## 인자

- **모드 + 대상** (`/agent-arch design 실행로그를 진단하는 헬프데스크 에이전트`)
- **scaffold + 이름** (`/agent-arch scaffold run_analyzer`)
- **review + 경로** (`/agent-arch review src/agents/help_desk/`)
- **인자 없음** → 3개 모드와 7원칙을 요약해 보여주고 모드·대상을 요청한 뒤 종료

사용자가 전달한 인자:

```text
$ARGUMENTS
```
