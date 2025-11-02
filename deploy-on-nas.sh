#!/bin/bash

# 在 NAS 上运行的部署脚本
# 使用方法：
# 1. 将此脚本上传到 NAS
# 2. 在 NAS 上执行: bash deploy-on-nas.sh <部署目录路径> [git仓库URL]

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 缺少部署目录参数${NC}"
    echo -e "${YELLOW}使用方法: bash deploy-on-nas.sh <部署目录路径> [git仓库URL]${NC}"
    echo "示例: bash deploy-on-nas.sh /volume1/web/my-ielts https://github.com/woaixiangbao/my-ielts.git"
    exit 1
fi

DEPLOY_DIR=$1
GIT_REPO=${2:-"https://github.com/woaixiangbao/my-ielts.git"}
BUILD_DIR="/tmp/my-ielts-build-$(date +%s)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}开始部署 IELTS 学习网站${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查必要的命令
echo -e "${GREEN}步骤 1: 检查环境...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}错误: 未找到 git，请先安装 git${NC}"
    exit 1
fi

if ! command -v node &> /dev/null && ! command -v nodejs &> /dev/null; then
    echo -e "${RED}错误: 未找到 Node.js，请先安装 Node.js${NC}"
    exit 1
fi

NODE_CMD="node"
if ! command -v node &> /dev/null; then
    NODE_CMD="nodejs"
fi

# 检查 Node.js 版本（建议 16+）
NODE_VERSION=$($NODE_CMD --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo -e "${YELLOW}警告: Node.js 版本较低（当前: $($NODE_CMD --version)），建议使用 Node.js 16 或更高版本${NC}"
fi

# 检查包管理器
if command -v pnpm &> /dev/null; then
    PKG_MANAGER="pnpm"
elif command -v yarn &> /dev/null; then
    PKG_MANAGER="yarn"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
else
    echo -e "${RED}错误: 未找到包管理器（pnpm/yarn/npm）${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 环境检查通过${NC}"
echo "   - Git: $(git --version)"
echo "   - Node.js: $($NODE_CMD --version)"
echo "   - 包管理器: $PKG_MANAGER"

# 克隆或更新仓库
echo -e "${GREEN}步骤 2: 获取源代码...${NC}"

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "正在克隆仓库: $GIT_REPO"
git clone "$GIT_REPO" .

echo -e "${GREEN}✓ 代码获取完成${NC}"

# 安装依赖
echo -e "${GREEN}步骤 3: 安装依赖...${NC}"

if [ "$PKG_MANAGER" = "pnpm" ]; then
    if ! command -v pnpm &> /dev/null; then
        echo "正在安装 pnpm..."
        npm install -g pnpm
    fi
    pnpm install --frozen-lockfile
elif [ "$PKG_MANAGER" = "yarn" ]; then
    yarn install --frozen-lockfile
else
    npm ci
fi

echo -e "${GREEN}✓ 依赖安装完成${NC}"

# 生成 vocabulary.js（如果需要 Python）
echo -e "${GREEN}步骤 4: 生成词汇数据...${NC}"

if command -v python3 &> /dev/null; then
    cd "$BUILD_DIR/src/pages/vocabulary"
    if [ -f "parser.py" ] && [ -f "vocabulary.txt" ]; then
        echo "正在生成 vocabulary.js..."
        python3 parser.py
        echo -e "${GREEN}✓ 词汇数据生成完成${NC}"
    else
        echo -e "${YELLOW}⚠ 未找到 parser.py 或 vocabulary.txt，跳过数据生成${NC}"
    fi
    cd "$BUILD_DIR"
else
    echo -e "${YELLOW}⚠ 未找到 Python3，跳过词汇数据生成${NC}"
    echo -e "${YELLOW}  如果需要生成 vocabulary.js，请先安装 Python3${NC}"
fi

# 构建项目
echo -e "${GREEN}步骤 5: 构建项目...${NC}"

if [ "$PKG_MANAGER" = "pnpm" ]; then
    pnpm run build
elif [ "$PKG_MANAGER" = "yarn" ]; then
    yarn build
else
    npm run build
fi

if [ ! -d "$BUILD_DIR/dist" ]; then
    echo -e "${RED}错误: 构建失败，未找到 dist 目录${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 构建完成${NC}"

# 部署到目标目录
echo -e "${GREEN}步骤 6: 部署文件...${NC}"

# 创建部署目录
mkdir -p "$DEPLOY_DIR"

# 备份旧版本（如果存在）
if [ -d "$DEPLOY_DIR" ] && [ "$(ls -A $DEPLOY_DIR)" ]; then
    BACKUP_DIR="${DEPLOY_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "正在备份旧版本到: $BACKUP_DIR"
    cp -r "$DEPLOY_DIR" "$BACKUP_DIR"
    echo -e "${GREEN}✓ 备份完成${NC}"
fi

# 复制文件
echo "正在复制文件到: $DEPLOY_DIR"
rsync -av --delete "$BUILD_DIR/dist/" "$DEPLOY_DIR/" || cp -r "$BUILD_DIR/dist/"* "$DEPLOY_DIR/"

echo -e "${GREEN}✓ 文件部署完成${NC}"

# 设置权限（根据你的 NAS 系统可能需要调整）
echo -e "${GREEN}步骤 7: 设置文件权限...${NC}"

# 常见 NAS 系统的 Web 服务器用户
WEB_USERS=("http" "www-data" "nginx" "apache" "httpd")
WEB_USER=""

for user in "${WEB_USERS[@]}"; do
    if id "$user" &>/dev/null; then
        WEB_USER="$user"
        break
    fi
done

if [ -n "$WEB_USER" ]; then
    chown -R "$WEB_USER:$WEB_USER" "$DEPLOY_DIR" 2>/dev/null || true
    echo "已设置所有者: $WEB_USER"
fi

chmod -R 755 "$DEPLOY_DIR" 2>/dev/null || true

echo -e "${GREEN}✓ 权限设置完成${NC}"

# 清理临时文件
echo -e "${GREEN}步骤 8: 清理临时文件...${NC}"
rm -rf "$BUILD_DIR"
echo -e "${GREEN}✓ 清理完成${NC}"

# 完成
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "部署目录: $DEPLOY_DIR"
echo ""
echo -e "${YELLOW}接下来的步骤:${NC}"
echo "1. 在 NAS Web 服务器中配置站点根目录为: $DEPLOY_DIR"
echo "2. 访问地址: http://你的NAS_IP:端口号"
echo "3. 如需更新，重新运行此脚本即可"

