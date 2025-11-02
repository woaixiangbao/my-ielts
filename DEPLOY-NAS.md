# 部署到 NAS 指南

## 快速部署

### 方法 1: 使用部署脚本（推荐）

```bash
./deploy-to-nas.sh <NAS_IP> <NAS_USER> <NAS_PATH>
```

示例：
```bash
./deploy-to-nas.sh 192.168.1.100 admin /volume1/web/my-ielts
```

### 方法 2: 手动部署

#### 步骤 1: 构建项目
```bash
pnpm run build
```

#### 步骤 2: 复制文件到 NAS

**通过文件共享（最简单）：**
1. 在 NAS 上创建共享文件夹，例如 `web` 或 `www`
2. 通过文件管理器访问 NAS 共享文件夹
3. 将 `dist` 文件夹中的**所有内容**复制到共享文件夹中

**通过 SSH：**
```bash
# 使用 scp
scp -r dist/* your_nas_user@your_nas_ip:/volume1/web/my-ielts/

# 或使用 rsync（推荐，支持增量同步）
rsync -avz --delete dist/ your_nas_user@your_nas_ip:/volume1/web/my-ielts/
```

#### 步骤 3: 配置 NAS Web 服务器

**群晖 (Synology):**
1. 打开 **套件中心** → 安装 **Web Station**
2. 打开 **Web Station** → **虚拟主机** → **新增**
3. 设置：
   - **端口**: 如 8080（或其他可用端口）
   - **文档根目录**: 指向你的部署文件夹（如 `/volume1/web/my-ielts`）
4. 保存后即可通过 `http://你的NAS_IP:端口号` 访问

**威联通 (QNAP):**
1. 打开 **App Center** → 安装 **Web Server**
2. 配置虚拟主机，指向部署文件夹
3. 设置端口并启动服务

**其他 NAS 品牌:**
- 查找 Web Server 或 HTTP Server 相关应用
- 配置站点根目录指向部署文件夹
- 设置端口（默认通常是 80 或 8080）

## 访问网站

部署完成后，在局域网内通过以下地址访问：
```
http://你的NAS_IP:端口号
```

例如：
```
http://192.168.1.100:8080
```

## 注意事项

1. **Hash 路由**: 本项目使用 Hash 路由模式（URL 格式为 `/#/path`），不需要服务器端路由重写配置

2. **文件权限**: 确保 Web 服务器对部署文件夹有读取权限

3. **音频文件**: 项目包含大量音频文件（约 3700+ 个），确保 NAS 有足够存储空间

4. **防火墙**: 如需从外网访问，需要在 NAS 防火墙设置中开放 Web 服务端口

5. **HTTPS（可选）**: 如需启用 HTTPS，可以使用 Let's Encrypt 证书（部分 NAS 支持自动申请）

## 更新部署

每次更新后，只需重新运行部署脚本或手动同步 `dist` 文件夹即可。

