# 在 NAS 上通过 Git 部署指南

本方案直接在 NAS 上克隆 Git 仓库并自动构建部署，更方便维护和更新。

## 前置要求

1. **Git**：NAS 需要安装 Git
2. **Node.js**：建议 Node.js 16 或更高版本
3. **包管理器**：pnpm（推荐）、yarn 或 npm
4. **Python 3**（可选）：用于生成 `vocabulary.js`，如果没有 Python，需要使用预生成的 `vocabulary.js`

## 部署步骤

### 方法 1: 使用自动部署脚本（推荐）

#### 步骤 1: 上传部署脚本到 NAS

将 `deploy-on-nas.sh` 上传到 NAS 的某个目录（例如 `/volume1/scripts/`）

#### 步骤 2: 设置执行权限

通过 SSH 连接到 NAS：
```bash
chmod +x /volume1/scripts/deploy-on-nas.sh
```

#### 步骤 3: 运行部署脚本

```bash
bash /volume1/scripts/deploy-on-nas.sh <部署目录> [git仓库URL]
```

**示例：**
```bash
# 使用默认仓库
bash /volume1/scripts/deploy-on-nas.sh /volume1/web/my-ielts

# 指定仓库
bash /volume1/scripts/deploy-on-nas.sh /volume1/web/my-ielts https://github.com/woaixiangbao/my-ielts.git
```

脚本会自动完成：
- ✅ 克隆/更新 Git 仓库
- ✅ 安装依赖
- ✅ 生成词汇数据（vocabulary.js）
- ✅ 构建项目
- ✅ 部署到指定目录
- ✅ 设置文件权限
- ✅ 清理临时文件

### 方法 2: 手动部署

#### 步骤 1: 克隆仓库

```bash
# 创建部署目录
mkdir -p /volume1/web/my-ielts-source
cd /volume1/web/my-ielts-source

# 克隆仓库
git clone https://github.com/woaixiangbao/my-ielts.git .

# 或如果目录已存在，更新代码
cd /volume1/web/my-ielts-source
git pull origin master
```

#### 步骤 2: 安装依赖

```bash
cd /volume1/web/my-ielts-source

# 如果有 pnpm（推荐）
pnpm install

# 或使用 npm
npm install

# 或使用 yarn
yarn install
```

#### 步骤 3: 生成词汇数据（如果有 Python3）

```bash
cd /volume1/web/my-ielts-source/src/pages/vocabulary
python3 parser.py
cd /volume1/web/my-ielts-source
```

#### 步骤 4: 构建项目

```bash
cd /volume1/web/my-ielts-source

# 使用 pnpm
pnpm run build

# 或使用 npm
npm run build

# 或使用 yarn
yarn build
```

#### 步骤 5: 复制构建产物

```bash
# 创建部署目录
mkdir -p /volume1/web/my-ielts

# 复制 dist 文件夹内容
cp -r /volume1/web/my-ielts-source/dist/* /volume1/web/my-ielts/
```

#### 步骤 6: 配置 Web 服务器

参考 [DEPLOY-NAS.md](./DEPLOY-NAS.md) 中的 Web 服务器配置部分。

## 更新部署

每次代码更新后，只需重新运行部署脚本或手动执行：

```bash
# 使用脚本
bash /volume1/scripts/deploy-on-nas.sh /volume1/web/my-ielts

# 或手动更新
cd /volume1/web/my-ielts-source
git pull origin master
pnpm install  # 如果有新依赖
cd src/pages/vocabulary && python3 parser.py && cd ../..
pnpm run build
cp -r dist/* /volume1/web/my-ielts/
```

## 自动化部署（可选）

### 使用 Cron 定时更新

在 NAS 上设置定时任务，每天自动拉取最新代码并部署：

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天凌晨 2 点自动更新）
0 2 * * * bash /volume1/scripts/deploy-on-nas.sh /volume1/web/my-ielts >> /volume1/scripts/deploy.log 2>&1
```

### 使用 Git Webhook（高级）

如果需要代码推送后自动部署，可以设置 Webhook：

1. 在 GitHub 仓库设置中添加 Webhook
2. 在 NAS 上运行一个简单的 Web 服务接收 Webhook 请求
3. 触发部署脚本执行

## NAS 特定说明

### 群晖 (Synology)

1. **安装 Git Server**：
   - 套件中心 → 搜索 "Git Server" → 安装

2. **安装 Node.js**：
   - 方法 1：套件中心 → Node.js v16/v18/v20（如果可用）
   - 方法 2：使用 Synology 社区的 Node.js 套件
   - 方法 3：通过 Docker 安装 Node.js

3. **安装 pnpm**（如果使用）：
   ```bash
   npm install -g pnpm
   ```

4. **Python**：
   - 套件中心 → Python 3（如果可用）

### 威联通 (QNAP)

1. **Git**：通过 `opkg install git` 或 Container Station 安装

2. **Node.js**：通过 Container Station 或手动编译安装

### 通用方案：Docker

如果 NAS 支持 Docker，可以使用 Docker 容器来运行构建：

```dockerfile
FROM node:18-alpine
RUN npm install -g pnpm
WORKDIR /app
COPY . .
RUN pnpm install && pnpm run build
```

## 文件权限

确保 Web 服务器用户有读取权限：

```bash
# 查找 Web 服务器用户
ps aux | grep -E 'nginx|httpd|apache'

# 设置权限（替换为你实际的 Web 服务器用户）
chown -R http:http /volume1/web/my-ielts
chmod -R 755 /volume1/web/my-ielts
```

## 常见问题

### Q: NAS 上没有 Git？

A: 可以通过包管理器安装，或使用 Docker 容器。

### Q: 构建时内存不足？

A: 增加 Node.js 内存限制：
```bash
export NODE_OPTIONS="--max-old-space-size=4096"
pnpm run build
```

### Q: 如何查看部署日志？

A: 脚本会输出详细日志，也可以重定向到文件：
```bash
bash deploy-on-nas.sh /volume1/web/my-ielts 2>&1 | tee deploy.log
```

### Q: 没有 Python3，vocabulary.js 怎么办？

A: 可以从本地项目复制已生成的 `vocabulary.js` 到 NAS 仓库中，或使用 Docker 运行 Python。

## 优势

✅ **版本控制**：代码变更可追踪
✅ **易于更新**：一条命令即可更新
✅ **自动化**：可配置定时或 Webhook 自动部署
✅ **回滚方便**：可以切换到任意 Git 版本

