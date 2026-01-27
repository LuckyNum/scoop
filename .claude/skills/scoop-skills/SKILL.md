# Scoop Create App

一个用于在 Scoop 中创建和发布新应用的专门技能。

## 何时使用此技能

当用户需要以下操作时使用：
- 为 Scoop 创建新的应用 manifest
- 创建自定义 bucket
- 向现有 bucket 添加应用
- 验证和测试 Scoop app manifest
- 了解 Scoop app 的最佳实践

## Scoop App 基础

### App Manifest 结构

Scoop app manifest 是一个 JSON 文件，描述如何下载、安装和检查应用更新。

```json
{
    "version": "1.0.0",
    "description": "应用描述",
    "homepage": "https://example.com",
    "license": "MIT",
    "url": "https://example.com/downloads/app-1.0.0.zip",
    "hash": "sha256:hash_value_here",
    "extract_dir": "app",
    "bin": "app.exe",
    "shortcuts": [
        ["app.exe", "应用名称"]
    ]
}
```

### 核心字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `version` | 是 | 应用版本号 |
| `description` | 推荐 | 应用描述 |
| `homepage` | 推荐 | 应用官网 |
| `license` | 推荐 | 开源协议 |
| `url` | 是 | 下载地址 |
| `hash` | 是 | 文件校验值（sha256/sha512/md5） |
| `extract_dir` | 可选 | 解压后的目录 |
| `bin` | 可选 | 可执行文件 |
| `shortcuts` | 可选 | 开始菜单快捷方式 |
| `persist` | 可选 | 持久化数据目录 |
| `installer` | 可选 | 安装程序配置 |

### 常见下载模式

#### 1. 简单单文件下载

```json
{
    "version": "1.0.0",
    "url": "https://example.com/app.exe",
    "hash": "sha256:hash_value"
}
```

#### 2. 压缩包下载

```json
{
    "version": "1.0.0",
    "url": "https://example.com/app-1.0.0.zip",
    "hash": "sha256:hash_value",
    "extract_dir": "app"
}
```

#### 3. 多架构下载

```json
{
    "version": "1.0.0",
    "architecture": {
        "64bit": {
            "url": "https://example.com/app-x64.zip",
            "hash": "sha256:hash64"
        },
        "32bit": {
            "url": "https://example.com/app-x86.zip",
            "hash": "sha256:hash32"
        },
        "arm64": {
            "url": "https://example.com/app-arm64.zip",
            "hash": "sha256:hasharm"
        }
    }
}
```

#### 4. GitHub Releases 自动更新

```json
{
    "version": "1.0.0",
    "description": "My App",
    "homepage": "https://github.com/user/repo",
    "license": "MIT",
    "url": "https://github.com/user/repo/releases/download/v1.0.0/app-1.0.0.zip",
    "hash": "sha256:hash_value",
    "autoupdate": {
        "url": "https://github.com/user/repo/releases/download/v$version/app-$version.zip"
    }
}
```

#### 5. 使用 checkver 自动检测版本

```json
{
    "version": "1.0.0",
    "homepage": "https://github.com/user/repo",
    "url": "https://github.com/user/repo/releases/download/v$version/app.zip",
    "hash": "sha256:hash_value",
    "checkver": "github",
    "autoupdate": {
        "url": "https://github.com/user/repo/releases/download/v$version/app.zip"
    }
}
```

### checkver 配置

`checkver` 用于自动检测新版本：

```json
{
    "checkver": {
        "url": "https://example.com/downloads",
        "regex": "app-([\\d.]+)\\.zip"
    }
}
```

#### 常用 checkver 模式

| 模式 | 用途 |
|------|------|
| `"github"` | GitHub Releases（自动检测） |
| `"sourceforge": "projectname"` | SourceForge |
| `regex` | 自定义正则表达式 |

### 持久化数据

```json
{
    "persist": [
        "config",
        "data"
    ]
}
```

### 环境变量

```json
{
    "env_add_path": "bin",
    "env_set": {
        "JAVA_HOME": "$dir"
    }
}
```

### 依赖关系

```json
{
    "depends": "python",
    "suggest": {
        "python": "To run scripts"
    }
}
```

### 安装前后脚本

```json
{
    "pre_install": "echo 'Installing...'",
    "post_install": "powershell -File install.ps1",
    "pre_uninstall": "powershell -File uninstall.ps1"
}
```

## 创建流程

### 1. 准备工作

```powershell
# 创建自定义 bucket
scoop bucket add my-bucket https://github.com/user/my-bucket

# 或使用本地 bucket
mkdir ~/scoop-buckets/my-bucket
cd ~/scoop-buckets/my-bucket
git init
```

### 2. 创建 App Manifest

在 bucket 目录下创建 `app-name.json`：

```powershell
# 计算文件 hash
Invoke-WebRequest -Uri "https://example.com/app.zip" -OutFile app.zip
Get-FileHash app.zip -Algorithm SHA256

# 或使用 scoop helper
scoop hash app.zip
```

### 3. 测试 Manifest

```powershell
# 从本地测试
scoop install --custom ../my-bucket/app-name.json

# 或从 bucket 测试
scoop install my-bucket/app-name

# 验证安装
scoop info app-name
```

### 4. 提交到 Bucket

```powershell
git add app-name.json
git commit -m "Add app-name (version)"
git push
```

## 最佳实践

### 1. 文件命名

- 使用小写字母和连字符：`my-app.json`
- 移除特殊字符：`my_app` → `my-app`
- 保持简洁有意义

### 2. 版本号选择

- 首选官方发布的版本号
- 使用语义化版本（如 `1.2.3`）
- 不要添加 `v` 前缀（除非 URL 需要）

### 3. Hash 算法

- 优先使用 `sha256`
- 大文件可用 `sha512`
- 避免使用 `md5`（不安全）

### 4. URL 选择

- 优先选择官方 CDN
- 避免使用临时链接
- 使用稳定的下载源

### 5. Autoupdate 设计

- 尽量支持自动更新
- 测试 URL 模板正确性
- 确保 hash 可自动获取（或省略）

### 6. 权限处理

- 便携版优先
- 避免需要管理员权限
- 不修改系统设置

## 常见问题

### Q: 如何处理安装程序？

使用 `installer` 字段：

```json
{
    "url": "https://example.com/setup.exe",
    "hash": "sha256:hash",
    "installer": {
        "script": "Expand-7zipArchive \"$dir\\setup.exe\" \"$dir\""
    }
}
```

### Q: 如何处理需要激活的应用？

Scoop 不支持付费/需激活的软件。请使用便携版或替代方案。

### Q: 如何处理多文件下载？

使用数组：

```json
{
    "url": [
        "https://example.com/app1.zip",
        "https://example.com/app2.zip"
    ],
    "hash": [
        "sha256:hash1",
        "sha256:hash2"
    ]
}
```

### Q: 如何处理中文路径？

使用 URL 编码或 PowerShell 转义：

```json
{
    "url": "https://example.com/%E4%B8%AD%E6%96%87.zip"
}
```

## 验证清单

提交前检查：

- [ ] 版本号正确
- [ ] URL 可访问
- [ ] Hash 匹配
- [ ] 可执行文件正确
- [ ] 描述清晰准确
- [ ] 开源协议明确
- [ ] autoupdate 配置正确（如适用）
- [ ] 测试安装成功
- [ ] 测试卸载成功
- [ ] 测试更新功能

## 示例模板

### 简单工具模板

```json
{
    "version": "1.0.0",
    "description": "A simple command-line tool",
    "homepage": "https://example.com",
    "license": "MIT",
    "url": "https://github.com/user/tool/releases/download/v1.0.0/tool-windows-amd64.zip",
    "hash": "sha256:placeholder",
    "bin": "tool.exe"
}
```

### GUI 应用模板

```json
{
    "version": "1.0.0",
    "description": "A GUI application",
    "homepage": "https://example.com",
    "license": "Proprietary",
    "url": "https://example.com/downloads/app-1.0.0.exe",
    "hash": "sha256:placeholder",
    "shortcuts": [
        ["app.exe", "My App"]
    ],
    "persist": "config"
}
```

### 开发工具模板

```json
{
    "version": "1.0.0",
    "description": "Development tool for XYZ",
    "homepage": "https://example.com",
    "license": "Apache-2.0",
    "url": "https://github.com/user/tool/releases/download/v1.0.0/tool-windows-x64.zip",
    "hash": "sha256:placeholder",
    "extract_dir": "tool",
    "bin": "bin/tool.exe",
    "env_add_path": "bin",
    "checkver": "github",
    "autoupdate": {
        "url": "https://github.com/user/tool/releases/download/v$version/tool-windows-x64.zip"
    }
}
```

## 相关资源

- [Scoop 官方文档](https://github.com/ScoopInstaller/Scoop/wiki)
- [App Manifest 规范](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests)
- [创建 App Manifest](https://github.com/ScoopInstaller/Scoop/wiki/Creating-an-app-manifest)
- [Main Bucket](https://github.com/ScoopInstaller/Main)
- [Extras Bucket](https://github.com/ScoopInstaller/Extras)
- [Scoop Directory](https://scoop.sh/)
