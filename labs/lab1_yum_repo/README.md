# 实验1：YUM 配置国内源

## 实验目的

将 Rocky Linux 9 默认的国外 YUM/DNF 源替换为阿里云镜像源，提升软件包下载速度。

## 实验要求

1. 备份原有 repo 配置文件
2. 配置阿里云 BaseOS 和 AppStream 仓库
3. 清理缓存并重建
4. 验证新源可用

## 操作步骤

### 1. 执行安装脚本

```bash
sudo bash setup.sh
```

### 2. 验证配置

```bash
sudo bash verify.sh
```

## 故障排查

### yum/dnf 命令报 404 或认证失败

Rocky 9 默认 repo 文件使用 `$contentdir` 变量（展开为 `/pub/rocky`），
国内镜像（中科大、阿里云）无此子目录。即使替换了域名，路径仍错误。

**修复方法**：

```bash
sudo sed -i 's|\$contentdir|rocky|g' /etc/yum.repos.d/rocky*.repo
sudo yum makecache
```

### 无法安装 git 时如何拉取本仓库

由于 git 需要 yum 安装，而 yum 又需要先修复 repo，形成死锁。
可先执行上述 `$contentdir` 修复，再 `yum install -y git`，
或通过 scp 从宿主机传入文件。

## 验收标准

- `verify.sh` 输出全部 [PASS]
- `dnf repolist` 显示阿里云仓库
- `dnf install` 可正常安装软件包
