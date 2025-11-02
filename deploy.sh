#!/bin/bash
# ============================================================
# deploy.sh — 自动部署脚本 (for Synology NAS + Docker)
# 功能：
#   1. 强制同步 GitHub 最新代码
#   2. 构建前端 (pnpm 优先 / npm 兜底)
#   3. 重启 Nginx 容器以加载新版本
# ============================================================

set -euo pipefail

# ==== 基本配置 ====
APP_DIR="$(cd "$(dirname "$0")" && pwd)"      # 当前仓库目录
PNPM_STORE="/volume1/docker/.pnpm-store"      # 依赖缓存目录（可选）
BRANCH="master"                                # 你的默认分支（若是 master 请改这里）
CONTAINER_NAME="my-ielts"                    # Nginx 容器名称

cd "$APP_DIR"

# ==== 1. 强制同步远端 ====
echo "==> Force syncing with remote branch: $BRANCH"
sudo docker run --rm \
  -v "$PWD":/repo \
  -w /repo \
  alpine/git fetch --all --prune
sudo docker run --rm \
  -v "$PWD":/repo \
  -w /repo \
  alpine/git reset --hard "origin/$BRANCH"
sudo docker run --rm \
  -v "$PWD":/repo \
  -w /repo \
  alpine/git clean -fd

# ==== 2. 构建项目 ====
echo "==> Building project (prefer pnpm, fallback to npm)"
sudo docker run --rm \
  -v "$PWD":/app \
  -v "$PNPM_STORE":/root/.pnpm-store \
  -w /app \
  node:18 bash -lc 'corepack enable && corepack prepare pnpm@latest --activate && \
    (pnpm install --frozen-lockfile || npm install) && \
    (pnpm build || npm run build)'

# ==== 3. 重启 Nginx 容器 ====
echo "==> Restarting Nginx container: $CONTAINER_NAME"
sudo docker restart "$CONTAINER_NAME" || echo "⚠️  容器未运行，请确认容器名称是否正确。"

echo "✅ 部署完成，网站已更新。"
