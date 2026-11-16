---
description: 타팀(인프라·아키·보안·기획) 협업 지침. 공유 문서 작성·검토, 회의록 분석, 상대 유형 판정·대응, 프로파일 축적. 기준은 collab-playbook/playbook.md
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/collab-playbook.md` 를 Read 로 읽는다 (skill).
4. collab-playbook.md 의 Step 1~4 를 **순서대로** 실행한다.
   - Step 1: 기준 `collab-playbook/playbook.md` + 대상 인물 프로파일 Read
   - Step 2: 모드 판정 (doc / meeting / respond / profile)
   - Step 3: 모드별 실행 — 회의 분석은 7개 절 전부, 내 쪽 문제와 과잉/과소 판정 필수
   - Step 4: 기준·프로파일 파일 갱신은 제안 후 승인 시에만
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다.

## 인자

`[모드] [대상]` 형태로 받는다. 모드 없으면 대상을 보고 추론한다.

- `/collab-playbook doc <문서 경로 | 작성 요청>` → 타팀 공유 문서 작성·검토
- `/collab-playbook meeting <회의록 경로 | 본문>` → 회의록 분석 + 프로파일 갱신 제안
- `/collab-playbook respond <식별자> <상황>` → 대응 방식 제안
- `/collab-playbook profile <식별자>` → 새 프로파일 추가

사용자가 전달한 인자:

```text
$ARGUMENTS
```
