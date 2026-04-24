#!/bin/bash
set -e

# 볼륨 마운트 후 첫 실행 시 기본 홈 환경 초기화
if [ ! -f ~/.initialized ]; then
    cp -rn /home/coder-skel/. ~/
    mkdir -p ~/workspace
    touch ~/.initialized
fi

exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --base-path "/${USERNAME}" \
    ~/workspace
