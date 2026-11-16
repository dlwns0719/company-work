---
name: agent-arch
type: skill
version: 1.0
description: >
  레퍼런스 에이전트 플랫폼 스타일의 아키텍처 하네스. 새 에이전트를 설계·스캐폴드·검토할 때
  이 원칙(계약우선·얇은agent/무거운domain·단방향의존·라우터가 횡단관심사·결정론우선·
  포트&어댑터·조합확장)에 맞추도록 안내한다.
scope: project
---

# /agent-arch — 에이전트 개발 아키텍처 하네스

> LLM 에이전트 플랫폼에 **새 에이전트를 뼈대에 맞춰 얹는** 지침.
> 레퍼런스 에이전트 플랫폼(core·domains·agents·services·evaluation 구성)을 실측해 도출한 철학을 재사용 가능하게 정리.
> 원 철학 문서: 레퍼런스 플랫폼의 `docs/architecture/agent-architecture-philosophy.md`.

## 무엇을 하나

3개 모드. 인자로 모드와 대상을 받는다.

- `/agent-arch design <에이전트 아이디어>` — 아이디어를 이 아키텍처로 **설계**(계층 배치·포트·의존 방향).
- `/agent-arch scaffold <이름>` — 뼈대에 맞는 **파일 골격 + 배선 체크리스트** 산출.
- `/agent-arch review <경로|설명>` — 기존 에이전트/설계를 **7원칙 대비 점검**(위반·개선).

파일을 만드는 건 사용자 승인 후. 기본은 설계·점검 산출만.

---

## 7대 원칙 (판단 기준 — 항상 이걸로 채점)

1. **계약 우선** — 에이전트는 단일 계약 `run(Query) -> Response` 하나. 고유 입출력은 자유 dict(`agent_params`/`agent_data`). → 조합·교체 가능해야 한다.
2. **얇은 agent, 무거운 domain** — 알고리즘은 domain(leaf)에. 에이전트는 계약변환·오케스트레이션 어댑터. 에이전트에 알고리즘이 있으면 냄새.
3. **단방향 의존** — `services → agents → core`. domain은 아무도 위로 import 안 하는 leaf. 역방향·순환 금지.
4. **횡단관심사는 라우터가** — 실험배정·메트릭로깅·피드백·인증은 라우터(경계)가 주입. 에이전트 본체는 이걸 호출하지 않는다. → 관찰성이 공짜로 따라온다.
5. **결정론 우선, LLM 최후** — 근거·검색·추출은 결정론(환각 0). LLM은 종합·최후 폴백. 결정론/LLM 경계 = 클래스 경계.
6. **포트&어댑터로 외부 격리** — 외부 시스템(타 에이전트·LLM·스토리지·blob)은 추상 포트 뒤. 변동을 어댑터에 가둬 계약을 지키고 mock 테스트를 가능케 한다.
7. **조합으로 확장** — 새 에이전트는 재구축이 아니라 뼈대 위 조합. 공유 인프라 재사용 + 라우터 복제.

---

## 계층 지도 (배치 판단)

```
services · 배선/노출   (라우터 = 실험+로깅+인증)
   ↓
agents · 얇은 어댑터    (BaseAgent 구현, 오케스트레이션만)
   ↓
core · 공유 인프라      (계약·LLM·프롬프트·RAG·인용·로깅·실험) ← 아무도 위로 import 안 함
domains · 무거운 로직   (leaf: 결정론엔진·그래프·추출·store, core/agents 무의존 → repo 분화 가능)
experimental · 그래프 백엔드  (agents가 런타임 위임, core.contracts만 의존)
evaluation · 비프로덕션 측정  (A/B·채점, 프로덕션 무영향)
```

**로직 소재 결정 트리**:
- 단순 LLM 체인 한두 개 → 에이전트 본체 inline.
- 서브단계 여럿(각각 계약 있는 단위) → `agents/{name}/sub_agents/`(각 BaseAgent) 또는 함수형.
- 무거운 알고리즘(AST·그래프·검색·추출) + 결정론 성립 + 재사용/무거운 부트스트랩 + 자립 가능 → `domains/{domain}/`(leaf).
- 복잡한 멀티-서브에이전트 그래프(LangGraph) → `experimental/{name}/`.

---

## Step 레시피 (scaffold/design 공통 뼈대)

**Step 1 — 계약(에이전트 본체)**
- `agents/{name}/agent.py`: `class XAgent(BaseAgent)`, `name="..."`, (선택 `domain=`).
- `run(query: Query) -> Response` 구현. 무거운 자원은 lazy(`_ensure_*`), latency/ttft 측정, `arm_id=query.arm_id` echo, 고유 출력은 `agent_data`.
- 외부 의존(LLM·타 에이전트·스토리지)은 **생성자 주입(DI seam)** — `XAgent(llm=, resolver=, ca_client=, ...)`. 원칙 6·테스트용.

**Step 2 — 포트 & 어댑터 (외부 의존이 있으면)**
- 포트(추상 인터페이스) 정의 → 어댑터(구현)로 배선. 외부 계약이 불확실할수록 포트 뒤로 숨긴다.
- 결정론 근거는 결정론 어댑터, LLM 종합만 LLM 어댑터로 분리(원칙 5).

**Step 3 — 로직 소재 배치**
- 위 결정 트리로 inline / sub_agents / domain / experimental 선택. domain에 두면 core·agents import 금지(격리 유지).

**Step 4 — 라우터 배선 (관찰성 공짜)**
- `services/api/routers/{name}.py` 를 기존 라우터 복제:
  - `router = APIRouter()`, `_agent_cache: dict[(exp,arm)->Agent]` + `Lock`
  - `_build_agent(user_id, force_arm)` — 실험 resolve + double-checked 캐시
  - `_build_query(req, exp, arm) -> Query`
  - `POST /run`(성공 `record_from_response` / 실패 `record_from_error`), `POST /stream`(SSE 또는 NDJSON, done/error/미종결 모두 로깅)
- `main.py` 2곳: 라우터 import + `include_router(prefix="/agents/{name}", dependencies=protected)`.
- 인증은 `dependencies=protected` 한 줄이면 끝(라우터 내부 작업 불필요).

**Step 5 — 테스트**
- 외부 의존은 mock(주입점 활용), LLM은 skip 아니라 `_FakeLLM` 주입(레포 컨벤션). 결정론 부분은 실코드.
- 계약 검증: `token→citation→done`, 에러 시 error 1프레임+done 미전송.

**Step 6 — 평가(선택)**
- 콜로케이트 `agents/{name}/eval/` + `data/eval/{name}/` 데이터셋(권장) 또는 중앙 `evaluation/` 어댑터.

---

## 결정 포인트 (선택지 — 상황따라)

| 결정 | 옵션 A | 옵션 B | 기준 |
|---|---|---|---|
| 실험 설정 | RAGConfig(`resolve_config_for_user`) | kwargs(`get_experiment_assignment`+override→kwarg 맵) | RAG 파라미터 위주면 A, 자유 kwargs면 B |
| 로직 분해 | sub_agents/(각 BaseAgent) | 함수형 | 단위마다 계약 있으면 A |
| 스트림 포맷 | SSE(`text/event-stream`) | NDJSON(`application/x-ndjson`) | 기존 FE 소비자와 맞춤 |
| 평가 | 콜로케이트 eval/ | 중앙 evaluation/ | 단독 재현이면 콜로케이트 권장 |

---

## 반드시(뼈대) vs 선택(정교화)

- **반드시**: BaseAgent 계약, 단방향 의존, 라우터가 실험·로깅·인증 주입, 결정론/LLM 경계, 외부의존 DI.
- **선택**: sub_agents 깊이, domain 승격, experimental 그래프, 스트림 방식, 평가 붙이기.

## 산출 양식
- **design**: 계층 배치표 + 포트 목록 + 의존방향 검증 + mermaid(선택) + 열린 결정.
- **scaffold**: 파일 트리 + Step별 체크리스트(각 파일 무엇을) + 라우터/ main.py 배선 diff 요지.
- **review**: 7원칙 각각 통과/위반 + 근거(파일:라인) + 개선안.

## 원칙 위반 레드플래그 (review 시)
- 에이전트 본체가 `log_run`/실험을 직접 호출 (→ 라우터로)
- 에이전트에 알고리즘 상주 (→ domain)
- domain이 core/agents import (→ 격리 위반)
- 근거 생성에 LLM 사용 (→ 결정론으로)
- 외부 의존이 하드코딩 import (→ 포트 주입)

$ARGUMENTS
