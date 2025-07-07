#!/bin/bash

set -e

# Docker 설치
echo "[+] Installing Docker..."
curl -fsSL https://get.docker.com -o docker-install.sh
sudo sh ./docker-install.sh
rm -f docker-install.sh

# Docker Compose 설치 (v2.23.0 기준)
echo "[+] Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.23.0"
sudo curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# docker 그룹에 현재 사용자 추가
echo "[+] Adding user '$USER' to docker group..."
sudo /usr/sbin/usermod -aG docker "$USER"

echo "[✓] Docker and Docker Compose installation completed!"
echo "=> 로그아웃 후 다시 로그인해야 docker 그룹 적용이 됩니다."
