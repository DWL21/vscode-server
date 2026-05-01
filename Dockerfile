FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 기본 도구 + C/C++
RUN apt-get update && apt-get install -y \
    curl git wget sudo \
    build-essential gcc g++ gdb make cmake \
    locales \
    && locale-gen ko_KR.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8

# 유틸리티
RUN apt-get update && apt-get install -y \
    jq tree tmux unzip zip \
    ripgrep fzf sqlite3 \
    bc lsof rsync strace \
    htop plocate \
    nano vim \
    && rm -rf /var/lib/apt/lists/*

# 네트워크 도구
RUN apt-get update && apt-get install -y \
    iputils-ping traceroute \
    net-tools iproute2 \
    netcat-openbsd dnsutils \
    ufw \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# zsh + 플러그인
RUN apt-get update && apt-get install -y \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    && rm -rf /var/lib/apt/lists/*

# 한글 폰트 + 폰트 도구
RUN apt-get update && apt-get install -y \
    fonts-noto-cjk fontconfig \
    && fc-cache -fv \
    && rm -rf /var/lib/apt/lists/*

# Python
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Java 21 JDK + Maven
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk maven \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Node.js 22 LTS (npm, npx 포함)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Cloudflare Wrangler / Claude Code / OpenAI Codex
RUN npm install -g \
    wrangler \
    @anthropic-ai/claude-code \
    @openai/codex

# code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ubuntu → coder (UID 1000 유지)
RUN usermod -l coder ubuntu \
    && usermod -d /home/coder -m coder \
    && groupmod -n coder ubuntu \
    && usermod -s /bin/zsh coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# oh-my-zsh 설치 (coder 홈에)
RUN su -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' coder

# zsh 플러그인 + alias 설정 (.zshrc에 추가)
RUN printf '\n\
# zsh 플러그인\n\
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh\n\
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n\
\n\
# apt 패키지 목록 저장\n\
alias apt-save='"'"'dpkg --get-selections | grep -v deinstall | awk "{print $1}" > ~/.apt-packages.txt && echo "[apt-save] saved"'"'"'\n\
\n\
# 편의 alias\n\
alias ll="ls -alF"\n\
alias la="ls -A"\n\
alias ..="cd .."\n\
alias ...="cd ../.."\n\
' >> /home/coder/.zshrc

# apt-save alias를 bash에도 추가
RUN echo '\nalias apt-save='"'"'dpkg --get-selections | grep -v deinstall | awk "{print \$1}" > ~/.apt-packages.txt && echo "[apt-save] $(wc -l < ~/.apt-packages.txt) packages saved"'"'" >> /etc/skel/.bashrc

# locate DB 초기 생성
RUN updatedb || true

# tmux 공유 세션 — 터미널 열면 자동 접속
RUN printf '\n# tmux 공유 세션\n\
tmux new-session -A -s shared\n\
alias q="tmux detach"\n\
	alias treset='"'"'tmux kill-session -t shared 2>/dev/null; tmux new-session -A -s shared'"'"'\n' >> /home/coder/.zshrc


RUN printf 'set -g mouse on\n\
set -g status on\n' > /home/coder/.tmux.conf

# 첫 실행 초기화용 기본 홈 스켈레톤 저장
RUN cp -rp /home/coder /home/coder-skel

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER coder
WORKDIR /home/coder

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
