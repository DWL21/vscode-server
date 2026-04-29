#!/bin/bash
set -e

# 볼륨 마운트 후 첫 실행 시 기본 홈 환경 초기화
if [ ! -f ~/.initialized ]; then
    cp -rn /home/coder-skel/. ~/
    mkdir -p ~/workspace
    touch ~/.initialized
fi

# code-server 비밀번호를 환경변수에서 덮어쓰기
mkdir -p ~/.config/code-server
cat > ~/.config/code-server/config.yaml <<EOF
bind-addr: 127.0.0.1:8080
auth: password
password: ${PASSWORD}
cert: false
EOF

# 현재 추가 설치된 패키지 목록 스냅샷 (이미지 기본 패키지 제외)
IMAGE_PACKAGES=/home/coder-skel/.image-packages.txt
SAVED_PACKAGES=~/.apt-packages.txt

if [ -f "$SAVED_PACKAGES" ]; then
    MISSING=$(comm -23 \
        <(sort "$SAVED_PACKAGES") \
        <(sudo dpkg --get-selections 2>/dev/null | grep -v deinstall | awk '{print $1}' | sort))
    if [ -n "$MISSING" ]; then
        echo ""
        echo "┌─────────────────────────────────────────────┐"
        echo "│  [!] 재빌드로 인해 누락된 apt 패키지:        │"
        echo "├─────────────────────────────────────────────┤"
        echo "$MISSING" | sed 's/^/│  /'
        echo "├─────────────────────────────────────────────┤"
        echo "│  sudo apt install \$(cat ~/.apt-packages.txt | tr '\\n' ' ')"
        echo "└─────────────────────────────────────────────┘"
        echo ""
    fi
fi

exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    ~/workspace
