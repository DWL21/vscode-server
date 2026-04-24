#!/usr/bin/env python3
"""
profiles.yml을 읽어 실습자용 접속 안내 문서(md + pdf)를 생성합니다.
생성 위치: docs/<name>.md, docs/<name>.pdf
"""
import yaml
import os
import subprocess
import shutil

PROFILES_FILE = "profiles.yml"
DOCS_DIR = "docs"
BASE_DOMAIN = "simplyimg.com"

TEMPLATE = """\
# VS Code Server 접속 안내

브라우저에서 아래 **접속 주소**로 들어간 뒤 **비밀번호**를 입력하면 바로 사용할 수 있습니다.

---

## 1. 접속

1. 브라우저 주소창에 `${{URL}}` 을 입력합니다.
2. 비밀번호 입력창에 `${{PASSWORD}}` 를 입력합니다.
3. **Submit** 버튼을 클릭합니다.

---

## 2. 처음 실행 시

접속하면 VS Code 편집기가 열립니다. 왼쪽 탐색기에 `workspace` 폴더가 기본 작업 공간입니다.

터미널을 열려면:
- 상단 메뉴 → **Terminal** → **New Terminal**
- 단축키: `` Ctrl + ` ``

---

## 3. 터미널 환경

기본 쉘은 **zsh** (oh-my-zsh)입니다.

```bash
# 현재 디렉토리 확인
pwd

# 파일 목록 보기
ls -la

# 작업 폴더로 이동
cd ~/workspace
```

---

## 4. 설치된 개발 도구

| 도구 | 명령어 | 확인 방법 |
|------|--------|-----------|
| Python 3 | `python3` | `python3 --version` |
| Java 21 | `java` | `java --version` |
| Node.js 22 | `node` | `node --version` |
| Git | `git` | `git --version` |
| GitHub CLI | `gh` | `gh --version` |
| Claude Code | `claude` | `claude --version` |
| OpenAI Codex | `codex` | `codex --version` |

---

## 5. 내 환경은 격리되어 있습니다

- 다른 실습자의 파일과 설정에 접근할 수 없습니다.
- `pip install`, `npm install`, `apt install` 등 자유롭게 설치할 수 있습니다.
- 설치한 패키지와 작업 파일은 서버를 재시작해도 유지됩니다.

---

## 6. 자주 쓰는 단축키

| 기능 | 단축키 |
|------|--------|
| 터미널 열기 | `` Ctrl + ` `` |
| 파일 검색 | `Ctrl + P` |
| 명령 팔레트 | `Ctrl + Shift + P` |
| 사이드바 토글 | `Ctrl + B` |
| 저장 | `Ctrl + S` |

---

## 접속 정보

| 항목 | 값 |
|------|-----|
| 접속 주소 | {url} |
| 비밀번호 | {password} |
"""


def load_profiles():
    with open(PROFILES_FILE) as f:
        return yaml.safe_load(f)["profiles"]


def generate_docs(profiles):
    os.makedirs(DOCS_DIR, exist_ok=True)

    md_to_pdf = shutil.which("md-to-pdf")

    for p in profiles:
        name = p["name"]
        url = f"https://{name}.{BASE_DOMAIN}/"
        password = p["password"]

        content = TEMPLATE.format(url=url, password=password)
        md_path = os.path.join(DOCS_DIR, f"{name}.md")

        with open(md_path, "w") as f:
            f.write(content)
        print(f"[+] {md_path}")

        if md_to_pdf:
            result = subprocess.run(
                [md_to_pdf, md_path],
                capture_output=True, text=True
            )
            pdf_path = md_path.replace(".md", ".pdf")
            if os.path.exists(pdf_path):
                print(f"[+] {pdf_path}")
            else:
                print(f"[!] PDF 변환 실패: {result.stderr.strip()}")
        else:
            print("[!] md-to-pdf 없음 — MD만 생성됨 (npm install -g md-to-pdf)")


if __name__ == "__main__":
    profiles = load_profiles()
    generate_docs(profiles)
    print(f"\n완료: docs/ 에 {len(profiles) * 2}개 파일 생성됨")
