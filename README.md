# VS Code Server

계정별로 격리된 VS Code Server 환경. Ubuntu 기반 컨테이너에서 실행되며 `simplyimg.com/<username>/` 으로 접속한다.

## 구조

```
vscode-server/
├── Dockerfile              # Ubuntu 24.04 + 개발 도구 + code-server
├── entrypoint.sh           # 컨테이너 시작 시 홈 디렉토리 초기화
├── generate.py             # profiles.yml → docker-compose.yml + nginx conf 생성
├── profiles.yml            # 계정 목록 (gitignore됨)
├── profiles.yml.example    # 계정 설정 샘플
├── nginx/conf.d/           # nginx 설정 (generate.py가 생성)
├── ssl/issue-cert.sh       # Cloudflare DNS로 SSL 인증서 발급
└── data/                   # 유저별 홈 디렉토리 (gitignore됨)
    └── <username>/         # /home/coder 전체 마운트 → 환경 완전 격리
```

## 격리 구조

```
[공유] Docker 이미지
  apt 패키지, code-server, wrangler, claude, codex 등 시스템 도구

[격리] data/<username>/ → 컨테이너 내 /home/coder/
  ├── workspace/        작업 파일
  ├── .config/          VS Code 설정, 익스텐션
  ├── .local/           pip install --user, npm 로컬 패키지
  ├── .gitconfig        Git 설정
  ├── .claude/          Claude Code 인증 정보
  └── .codex/           OpenAI Codex 인증 정보
```

## 최초 설정

### 1. 사전 요구사항

```bash
sudo apt install docker.io docker-compose-v2 python3-yaml
sudo usermod -aG docker $USER
```

### 2. SSL 인증서 발급

Cloudflare API Token 생성 후 저장한다 (권한: Zone:DNS:Edit, Zone:Zone:Read).

```bash
echo "dns_cloudflare_api_token = YOUR_TOKEN" | sudo tee /etc/letsencrypt/cloudflare.ini
sudo chmod 600 /etc/letsencrypt/cloudflare.ini

./ssl/issue-cert.sh
```

### 3. 계정 파일 생성

```bash
cp profiles.yml.example profiles.yml
```

`profiles.yml` 을 열어 계정명과 비밀번호를 설정한다.

```yaml
profiles:
  - name: alice
    password: "강력한_비밀번호"
  - name: bob
    password: "강력한_비밀번호"
```

### 4. 설정 생성 및 실행

```bash
python3 generate.py
docker compose up -d
```

## 사용자 관리

### 사용자 추가

`profiles.yml` 에 항목을 추가한다.

```yaml
profiles:
  - name: alice
    password: "..."
  - name: charlie    # 추가
    password: "..."
```

```bash
python3 generate.py
docker compose up -d
docker compose exec nginx nginx -s reload
```

### 사용자 제거

`profiles.yml` 에서 항목을 삭제한다.

```bash
python3 generate.py
docker compose up -d
docker compose rm <username>

# 데이터까지 삭제할 경우 (복구 불가)
rm -rf data/<username>/
```

### 비밀번호 변경

`profiles.yml` 에서 비밀번호 수정 후 해당 컨테이너만 재시작한다.

```bash
python3 generate.py
docker compose up -d --no-deps <username>
```

## 운영

### 상태 확인

```bash
docker compose ps
docker compose logs -f <username>
```

### 전체 재시작

```bash
docker compose restart
```

### 이미지 재빌드 (apt 패키지 추가 시)

`Dockerfile` 수정 후 재빌드한다. 유저 데이터(`data/`)는 유지된다.

```bash
docker compose build
docker compose up -d
```

### nginx 설정 반영

```bash
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload
```

## 설치된 개발 환경

| 분류 | 도구 |
|------|------|
| Python | python3, pip, venv |
| Java | OpenJDK 21, Maven |
| C/C++ | gcc, g++, gdb, make, cmake |
| JavaScript | Node.js 20 LTS, npm, npx |
| Cloudflare | wrangler (Workers/Pages CLI) |
| AI | Claude Code (`claude`), OpenAI Codex (`codex`) |
| 기타 | git, gh, jq, httpie, ripgrep, fzf, tmux, sqlite3 |

## 접속

```
https://simplyimg.com/<username>/
```

비밀번호는 `profiles.yml` 에 설정한 값을 사용한다.
