#!/bin/bash
# 在NAS上部署当前项目，部署脚本：build + restart
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"  # 当前仓库目录
PNPM_STORE="/volume1/docker/.pnpm-store"  # 可选缓存

cd "$APP_DIR"

echo "==> Pull latest code"
sudo docker run --rm \
  -v "$PWD":/repo \
  -w /repo \
  alpine/git pull

echo "==> Build (prefer pnpm, fallback to npm)"
sudo docker run --rm \
  -v "$PWD":/app \
  -v "$PNPM_STORE":/root/.pnpm-store \
  -w /app \
  node:18 bash -lc 'corepack enable && corepack prepare pnpm@latest --activate && \
    (pnpm install --frozen-lockfile || npm install) && \
    (pnpm build || npm run build)'

echo "==> Restart nginx container"
sudo docker restart my-ielts

echo "✅ Done. Site updated!"
