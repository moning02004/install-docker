#!/usr/bin/env bash
# Docker Engine + Compose(플러그인) 설치 스크립트
# 사용법: ./install-docker.sh   (일반 사용자로 실행, 내부에서 sudo 사용)
set -euo pipefail

log()  { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }

# 1) 실행 사용자 확인 (sudo로 실행해도 실제 사용자를 docker 그룹에 추가)
TARGET_USER="${SUDO_USER:-$USER}"
if [[ "$TARGET_USER" == "root" ]]; then
  warn "root로 실행 중입니다. docker 그룹 추가 단계는 건너뜁니다."
fi

# 2) Docker Engine 설치 (공식 편의 스크립트)
#    → docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin,
#      docker-compose-plugin 까지 패키지로 설치됨 (최신 안정 버전)
if command -v docker >/dev/null 2>&1; then
  log "Docker가 이미 설치되어 있습니다: $(docker --version)"
  log "업데이트는 패키지 매니저(apt/dnf upgrade)로 진행하세요."
else
  log "Installing Docker Engine..."
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL https://get.docker.com -o "$tmp"
  sudo sh "$tmp"
fi

# 3) 서비스 활성화 (부팅 시 자동 시작)
log "Enabling docker & containerd services..."
sudo systemctl enable --now docker.service containerd.service

# 4) 'docker-compose'(하이픈) 명령 호환용 래퍼
#    별도 바이너리를 내려받지 않고 플러그인(docker compose)을 그대로 호출 →
#    패키지 업데이트 시 함께 최신으로 유지됨
if ! command -v docker-compose >/dev/null 2>&1; then
  log "Creating 'docker-compose' compatibility wrapper..."
  sudo tee /usr/local/bin/docker-compose >/dev/null <<'EOF'
#!/bin/sh
exec docker compose "$@"
EOF
  sudo chmod +x /usr/local/bin/docker-compose
fi

# 5) docker 그룹에 사용자 추가
if [[ "$TARGET_USER" != "root" ]]; then
  log "Adding user '$TARGET_USER' to docker group..."
  sudo usermod -aG docker "$TARGET_USER"
fi

# 6) 설치 확인
log "Installed versions:"
sudo docker version --format '  Engine : {{.Server.Version}}'
sudo docker compose version | sed 's/^/  /'
sudo docker buildx version | sed 's/^/  /'

echo
log "완료! docker 그룹 적용을 위해 로그아웃 후 다시 로그인하세요."
echo "    (바로 쓰려면: newgrp docker)"
warn "docker 그룹은 사실상 root 권한과 같습니다. 신뢰하는 사용자만 추가하세요."
