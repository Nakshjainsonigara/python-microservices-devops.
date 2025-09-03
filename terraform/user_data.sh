#!/bin/bash
set -euo pipefail

DOCKERHUB_USERNAME="${dockerhub_username}"
TAG="${tag}"

echo "[user-data] Installing Docker & dependencies..."

if command -v dnf >/dev/null 2>&1; then
  dnf update -y
  dnf install -y docker python3-pip
elif command -v yum >/dev/null 2>&1; then
  amazon-linux-extras install -y docker || true
  yum install -y docker python3-pip
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y docker.io python3-pip
else
  echo "Unsupported package manager" >&2
  exit 1
fi

systemctl enable docker
systemctl start docker

echo "[user-data] Installing docker-compose (via pip)..."
pip3 install --no-cache-dir docker-compose

mkdir -p /opt/app
cd /opt/app

cat > .env <<EOF
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME}
TAG=${TAG}
EOF

cat > docker-compose.yml <<'COMPOSEEOF'
services:
  backend:
    image: ${DOCKERHUB_USERNAME}/backend:${TAG:-latest}
    restart: unless-stopped
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=app
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_PORT=5432
      - LOGGER_URL=http://logger:6000/log
    ports:
      - "5000:5000"
    depends_on:
      postgres:
        condition: service_healthy

  frontend:
    image: ${DOCKERHUB_USERNAME}/frontend:${TAG:-latest}
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      - BACKEND_URL=http://backend:5000/api/data
    ports:
      - "8080:80"

  logger:
    image: ${DOCKERHUB_USERNAME}/logger:${TAG:-latest}
    restart: unless-stopped
    volumes:
      - ./logs:/logs
    ports:
      - "6000:6000"

  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d app"]
      interval: 5s
      timeout: 3s
      retries: 20

networks:
  default:
    name: microservices-net

volumes:
  db_data:
COMPOSEEOF

echo "[user-data] Pulling and starting containers..."
docker-compose --env-file .env pull
docker-compose --env-file .env up -d

echo "[user-data] Deployment complete."
