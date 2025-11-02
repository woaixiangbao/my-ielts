#!/bin/bash

# NAS 部署脚本
# 使用方法：./deploy-to-nas.sh [NAS_IP] [NAS_USER] [NAS_PATH]

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始部署到 NAS...${NC}"

# 检查参数
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo -e "${YELLOW}使用方法: ./deploy-to-nas.sh <NAS_IP> <NAS_USER> <NAS_PATH>${NC}"
    echo "示例: ./deploy-to-nas.sh 192.168.1.100 admin /volume1/web/my-ielts"
    exit 1
fi

NAS_IP=$1
NAS_USER=$2
NAS_PATH=$3

# 1. 构建项目
echo -e "${GREEN}步骤 1: 构建项目...${NC}"
pnpm run build

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}构建失败，请检查错误信息${NC}"
    exit 1
fi

# 2. 同步文件到 NAS
echo -e "${GREEN}步骤 2: 同步文件到 NAS...${NC}"
echo "目标: ${NAS_USER}@${NAS_IP}:${NAS_PATH}"

# 使用 rsync 同步（如果可用），否则使用 scp
if command -v rsync &> /dev/null; then
    rsync -avz --delete --progress dist/ ${NAS_USER}@${NAS_IP}:${NAS_PATH}/
    echo -e "${GREEN}✓ 使用 rsync 同步完成${NC}"
else
    echo -e "${YELLOW}未找到 rsync，使用 scp 复制...${NC}"
    scp -r dist/* ${NAS_USER}@${NAS_IP}:${NAS_PATH}/
    echo -e "${GREEN}✓ 使用 scp 复制完成${NC}"
fi

echo -e "${GREEN}✓ 部署完成！${NC}"
echo -e "${GREEN}访问地址: http://${NAS_IP}:端口号${NC}"

