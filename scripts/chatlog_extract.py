#!/usr/bin/env python3
"""그날(KST) 이 컴퓨터의 Claude Code 채팅 로그와 git 커밋을 프로젝트별로 뽑아 markdown 으로 출력한다.

/daily-log 자동 모드(work-auto.sh)가 쓰는 고정 추출기다. 에이전트가 임의 코드를 돌리지 않고
이 스크립트 하나만 실행하도록 해서, 무인 실행 중 채팅 로그 안의 텍스트가 명령처럼 작동할 여지를 줄인다.

사용:
    python3 -I scripts/chatlog_extract.py [YYYY-MM-DD]

출력 규칙:
- 사용자 입력은 사람이 친 글만 (도구 결과·메타·요약·서브에이전트·시스템 태그 제외).
  문자열로 저장된 입력과, 리스트의 text 조각으로 저장된 입력(작업 중 보낸 메시지·붙여 넣은 글) 둘 다 읽는다.
- 어시스턴트는 한 입력에 대한 마지막 텍스트 응답만 남긴다(진행 중 문구는 빼고 결과만).
  긴 세션도 하루치 요청·결과가 상한 안에 들어가게 하기 위해서다.
- 자동 실행 세션(첫 입력에 AUTO_MARKER 포함)은 제외
- 메시지·세션·전체 길이에 상한을 둔다
"""
import json
import re
import subprocess
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

KST = timezone(timedelta(hours=9))
PROJECTS = Path.home() / ".claude" / "projects"
AUTO_MARKER = "[work-auto]"
USER_MAX = 300
ASSIST_MAX = 300
SESSION_MAX = 20000
TOTAL_MAX = 150000
# 채팅에 붙여 넣은 토큰·키가 추출물로 넘어가지 않게 가린다 (JWT, 긴 영숫자 덩어리, key=value 형태 비밀값).
SECRET_PATTERNS = [
    re.compile(r"eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]+)?"),
    re.compile(r"(?i)((?:key|token|secret|password|pat|sig)[\w-]*\s*[=:]\s*)\S{8,}"),
    re.compile(r"[A-Za-z0-9+/_-]{40,}={0,2}"),
]


def _kst_range(day):
    start = datetime(day.year, day.month, day.day, tzinfo=KST)
    return start, start + timedelta(days=1)


def _parse_ts(raw):
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except (AttributeError, ValueError):
        return None


def _mask(text):
    text = SECRET_PATTERNS[0].sub("[가림]", text)
    text = SECRET_PATTERNS[1].sub(lambda m: m.group(1) + "[가림]", text)
    return SECRET_PATTERNS[2].sub("[가림]", text)


def _clip(text, limit):
    flat = _mask(" ".join(text.split()))
    return flat if len(flat) <= limit else flat[:limit] + " ..."


def _assistant_text(msg):
    content = msg.get("content")
    if not isinstance(content, list):
        return ""
    parts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
    return " ".join(p for p in parts if p)


def _user_text(content):
    """사람이 친 글만 꺼낸다. 도구 결과·시스템 태그·중단 표시는 빈 문자열."""
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        if any(isinstance(c, dict) and c.get("type") == "tool_result" for c in content):
            return ""
        text = " ".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text")
    else:
        return ""
    text = text.strip()
    if not text or text.startswith("<") or text.startswith("[Request interrupted"):
        return ""
    return text


def _session_lines(path, start, end):
    """한 세션 파일에서 기간 안의 (시각, 역할, 내용) 목록과 cwd 를 돌려준다. 자동 실행 세션이면 None."""
    lines, cwd, first_user = [], None, None
    with path.open(encoding="utf-8", errors="ignore") as fh:
        for raw in fh:
            try:
                d = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if d.get("isSidechain") or d.get("isMeta") or d.get("isCompactSummary"):
                continue
            kind = d.get("type")
            if kind not in ("user", "assistant"):
                continue
            ts = _parse_ts(d.get("timestamp"))
            if ts is None:
                continue
            msg = d.get("message") or {}
            if kind == "user":
                content = _user_text(msg.get("content"))
                if not content:
                    continue
                if first_user is None:
                    first_user = content
                if not (start <= ts < end):
                    continue
                cwd = d.get("cwd") or cwd
                lines.append((ts, "U", _clip(content, USER_MAX)))
            else:
                if not (start <= ts < end):
                    continue
                text = _assistant_text(msg)
                if not text:
                    continue
                # 같은 입력에 대한 응답이 여럿이면 마지막 것만 남긴다
                if lines and lines[-1][1] == "A":
                    lines[-1] = (ts, "A", _clip(text, ASSIST_MAX))
                else:
                    lines.append((ts, "A", _clip(text, ASSIST_MAX)))
    if first_user is not None and AUTO_MARKER in first_user:
        return None, None
    return lines, cwd


def _git_commits(repo, day):
    try:
        top = subprocess.run(["git", "-C", repo, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=10)
        if top.returncode != 0:
            return []
        root = top.stdout.strip()
        author = subprocess.run(["git", "-C", root, "config", "user.name"],
                                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=10).stdout.strip()
        args = ["git", "-C", root, "log", "--all", f"--since={day} 00:00", f"--until={day} 23:59:59",
                "--pretty=format:%h %ad %s", "--date=format:%H:%M"]
        if author:
            args.append(f"--author={author}")
        out = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=20).stdout
        return [ln for ln in out.splitlines() if ln.strip()]
    except (OSError, subprocess.SubprocessError):
        return []


def collect(day):
    start, end = _kst_range(day)
    floor = (start - timedelta(days=1)).timestamp()
    by_project, seen = {}, set()
    # 분기(fork)한 세션은 분기 전 대화를 복사해 갖고 있다. 오래된 세션부터 읽어 같은 메시지는 처음 것만 남긴다.
    for path in sorted(PROJECTS.glob("*/*.jsonl"), key=lambda p: p.stat().st_ctime):
        if path.stat().st_mtime < floor:
            continue
        lines, cwd = _session_lines(path, start, end)
        if not lines:
            continue
        lines = [ln for ln in lines if ln not in seen]
        seen.update(lines)
        if not lines:
            continue
        key = cwd or path.parent.name
        by_project.setdefault(key, []).append(sorted(lines))
    return by_project


def render(day, by_project):
    out = [f"# 채팅·커밋 추출 {day} (KST)", ""]
    if not by_project:
        out.append("- 그날 채팅 기록 없음")
    for project in sorted(by_project):
        out.append(f"## {project}")
        for idx, lines in enumerate(by_project[project], 1):
            body, size = [], 0
            for ts, role, text in lines:
                row = f"- {ts.astimezone(KST):%H:%M} {role}: {text}"
                size += len(row)
                if size > SESSION_MAX:
                    body.append("- (이하 생략)")
                    break
                body.append(row)
            out.append(f"### 세션 {idx}")
            out.extend(body)
        commits = _git_commits(project, day) if Path(project).is_dir() else []
        out.append("### 커밋")
        out.extend(f"- {c}" for c in commits) if commits else out.append("- 없음")
        out.append("")
    text = "\n".join(out)
    return text if len(text) <= TOTAL_MAX else text[:TOTAL_MAX] + "\n\n(전체 상한 도달, 이하 생략)"


def main():
    # Windows 콘솔 기본 인코딩(cp949)으로는 이모지 등 일부 문자를 못 찍는다.
    sys.stdout.reconfigure(encoding="utf-8")
    arg =sys.argv[1] if len(sys.argv) > 1 else datetime.now(KST).strftime("%Y-%m-%d")
    try:
        day = date.fromisoformat(arg)
    except ValueError:
        print(f"날짜 형식 오류: {arg} (YYYY-MM-DD)", file=sys.stderr)
        return 2
    print(render(day, collect(day)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
