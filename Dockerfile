FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 기본 도구 + C/C++
RUN apt-get update && apt-get install -y \
    curl git wget vim sudo \
    build-essential gcc g++ gdb make cmake \
    locales \
    # 유틸리티
    jq tree tmux unzip zip \
    ripgrep fzf httpie sqlite3 \
    && locale-gen ko_KR.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8

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

# Cloudflare Wrangler (Pages & Workers CLI)
# Claude Code
# OpenAI Codex
RUN npm install -g \
    wrangler \
    @anthropic-ai/claude-code \
    @openai/codex

# code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

RUN usermod -l coder ubuntu \
    && usermod -d /home/coder -m coder \
    && groupmod -n coder ubuntu \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# apt-save 명령어 등록 (설치 목록을 홈 볼륨에 저장)
RUN echo '\n# apt 패키지 목록 저장\nalias apt-save='"'"'dpkg --get-selections | grep -v deinstall | awk "{print \$1}" > ~/.apt-packages.txt && echo "[apt-save] $(wc -l < ~/.apt-packages.txt) packages saved to ~/.apt-packages.txt"'"'" >> /etc/skel/.bashrc

# 첫 실행 초기화용 기본 홈 스켈레톤 저장
RUN cp -rp /home/coder /home/coder-skel

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER coder
WORKDIR /home/coder

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
