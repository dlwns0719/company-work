---
description: 과제 폴더 정리. 과제별 산출물을 records/projects/<slug>/ 에 모으고 목차(README.md)를 최신으로 유지한다. new·add·index·sweep 모드.
---

프로젝트 하네싱 체인에 따라 작업한다.

## 실행 순서

1. `GUIDE.md` 를 Read 로 읽는다 (라우팅 테이블).
2. `guides/GUIDE_CORE.md` 를 Read 로 읽는다 (공통 규칙).
3. `guides/project-note.md` 를 Read 로 읽는다 (skill).
4. project-note.md 의 Step 을 **순서대로** 실행한다. 각 Step 시작 시 무엇을 하는지 한 줄로 밝힌다.
   - **확인 전 파일 이동 금지**. 지우지 않고 `old/` 로 옮긴다. 파일 이름을 바꾸지 않는다
5. 보고 전 `guides/GUIDE_CORE.md` §5 Self-Check 를 출력한다. `--auto` 로 불렸으면 가이드의 자동 모드 절을 따르고 Self-Check 를 생략한다.

## 인자

`<new|add|index|sweep> [slug] [대상]`. 모드가 없으면 `index`.

사용자가 전달한 인자:

```text
$ARGUMENTS
```
