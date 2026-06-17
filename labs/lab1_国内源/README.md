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

## 验收标准

- `verify.sh` 输出全部 [PASS]
- `dnf repolist` 显示阿里云仓库
- `dnf install` 可正常安装软件包
