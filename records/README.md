# records — 업무 기록

이 폴더에 실제 업무 기록이 쌓인다. **main 브랜치에는 이 안내문만 있다.** 기록은 회사 브랜치에서만 만들고 커밋한다.

회사 브랜치를 처음 만들 때 한 번 실행한다.

```bash
git switch -c <회사이름>
cp config/company.example.env config/company.env   # 값 채우기
bash scripts/init-records.sh
```

## 구조

```text
records/
├── todo.md                         할 일 목록 (단일 원본, T-NNN)
├── inbox/                          아직 처리하지 않은 입력이 들어오는 한 곳
│   ├── transcripts/                회의 전사(*.transcript.txt)와 녹음. 처리되면 회의 폴더로 옮겨진다
│   └── notes/                      메모·받은 자료
├── daily/YYYY-MM/
│   ├── YYYY-MM-DD-brief.md         출근 브리핑 (아침 자동)
│   └── YYYY-MM-DD-log.md           업무 일지 (저녁 자동)
├── meetings/
│   ├── YYYY-MM/YYYY-MM-DD-<slug>/
│   │   ├── minutes.md              회의록
│   │   ├── transcript.txt          전사 원문
│   │   └── recording.webm          녹음 (git 추적 안 함)
│   └── series/<slug>.md            여러 번 이어지는 회의의 회차·누적 결정·이월 미결
├── weekly/YYYY/YYYY-Www.md         주간보고
├── projects/<slug>/                과제별 산출물 (보고 자료·조사·그림). README.md 가 목차다
├── team/                           팀 단위 기록 (정체성·운영 계획·원문)
└── _system/                        자동 처리용. 평소 열 필요 없다
    ├── sources/{chat,outlook,teams}/   수집 원본 (git 추적 안 함)
    ├── state/                      meetings.md · glossary.md · holidays.txt · runs.tsv
    ├── queue/tracker-pending.md    이슈 트래커 반영 대기열
    └── logs/YYYY-MM/               자동 실행 로그 (git 추적 안 함)
```

## 왜 이렇게 나눴나

| 규칙 | 이유 |
|---|---|
| 브리핑과 일지를 같은 달 폴더에 날짜순으로 둔다 | 하루의 아침·저녁이 나란히 보인다. 달이 바뀌어도 한 폴더가 계속 커지지 않는다 |
| 회의 하나가 폴더 하나다 | 회의록과 전사 원문이 한자리에 있다. 받은 자료·그림도 같이 둘 수 있다 |
| 이어지는 회의는 `series/` 에 묶는다 | 2회차 회의록을 쓸 때 1회차의 미결·결정을 다시 찾지 않는다 |
| 처리 전 입력은 `inbox/` 한 곳이다 | "미처리 전사" 를 한 폴더만 보고 판단한다 |
| 과제 산출물은 `projects/<slug>/` 에 둔다 | 일지의 근거 경로가 한 곳을 가리킨다. 임시 폴더가 생기지 않는다 |
| 자동 실행 결과는 `runs.tsv` 한 파일에 쌓는다 | 실패·빠진 날을 로그를 뒤지지 않고 찾는다 |
