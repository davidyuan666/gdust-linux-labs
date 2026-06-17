# Rocky Linux 9.8 安装指南

## 1. 为什么选 Rocky Linux 9.8

- Rocky Linux 是 RHEL（Red Hat Enterprise Linux）的下游发行版，**100% 兼容 RHEL**
- 9.8 是 9.x 系列最新稳定版（2026-05-25 发布），软件包较新
- 社区活跃，被广泛用于服务器和开发环境
- 作为 CentOS 的替代品，生态成熟

## 2. 三种 ISO 对比

| ISO 类型 | 文件大小 | 安装方式 | 适用场景 |
|----------|----------|----------|----------|
| **Boot ISO** | ~1.4 GB | 网络安装，按需下载包 | **推荐** — 小实验、虚拟机测试 |
| **DVD ISO** | ~14.2 GB | 完整离线安装 | 无网络环境、批量部署 |
| **Minimal ISO** | ~2.6 GB | 离线最小化安装 | 纯命令行服务器、极简环境 |

## 3. 下载

### 中科大镜像源（推荐）

```
https://mirrors.ustc.edu.cn/rocky/9.8/isos/x86_64/Rocky-9.8-x86_64-boot.iso
```

- 文件大小：约 1.38 GB
- 国内访问速度快

### 备用：官方源

```
https://download.rockylinux.org/pub/rocky/9.8/isos/x86_64/Rocky-9.8-x86_64-boot.iso
```

## 4. VirtualBox 虚拟机配置

| 配置项 | 建议值 |
|--------|--------|
| 类型 | Linux / Red Hat (64-bit) |
| 内存 | 2048 MB 以上 |
| CPU | 2 核以上 |
| 虚拟硬盘 | 20 GB 动态分配 |
| 网络 | NAT（默认） |
| 显存 | 128 MB（如需 GUI） |

### 创建步骤

1. VirtualBox → 新建
2. 名称：`Rocky-9.8`，类型：`Linux`，版本：`Red Hat (64-bit)`
3. 内存：建议 `2048 MB`
4. 虚拟硬盘：`现在创建虚拟硬盘` → VDI → 动态分配 → 20 GB
5. 创建完成后 → 设置 → 存储 → 选择 Boot ISO 镜像

## 5. 安装流程

### 5.1 启动

启动虚拟机，选择 **Install Rocky Linux 9.8**

### 5.2 语言

选择 `English (United States)` 或 `中文（简体）`，点击 Continue

### 5.3 安装目标 (Installation Destination)

- 选择自动创建的虚拟硬盘
- Storage Configuration 选 `Automatic`（自动分区即可）

### 5.4 软件选择 (Software Selection)

- **Minimal Install** — 纯命令行，适合服务器/小实验
- **Server with GUI** — 带 GNOME 桌面
- **Workstation** — 带桌面 + 开发工具

> 小实验建议选 **Minimal Install**，体量最小

### 5.5 用户设置

- 设置 **Root Password**
- 可选：创建普通用户（勾选 `Make this user administrator`）

### 5.6 网络与主机名

- 确认网卡已开启（默认 NAT 模式自动获取 IP）
- 可设置主机名，如 `rocky.local`

### 5.7 开始安装

点击 **Begin Installation**，等待完成。安装过程中需要联网下载包，耗时取决于网速。

完成后点击 **Reboot System**，移除光盘镜像。

## 6. 安装后配置

### 6.1 更新系统

```bash
sudo dnf update -y
```

### 6.2 安装 Guest Additions（可选）

```bash
# 安装依赖
sudo dnf install -y gcc kernel-devel kernel-headers elfutils-libelf-devel

# 挂载 Guest Additions 光盘（VirtualBox 菜单 → 设备 → 安装增强功能）
sudo mount /dev/cdrom /mnt
cd /mnt
sudo ./VBoxLinuxAdditions.run

# 重启
sudo reboot
```

### 6.3 允许 sudo 无需密码（可选）

```bash
sudo visudo
# 添加：username ALL=(ALL) NOPASSWD: ALL
```

### 6.4 配置软件源为中科大镜像（加速包管理）

```bash
sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.ustc.edu.cn/rocky|g' \
         -i.bak /etc/yum.repos.d/rocky*.repo

sudo dnf makecache
```

### 6.5 安装常用工具

```bash
sudo dnf install -y vim git curl wget net-tools
```

## 7. 常见问题

### Q: 安装时提示网络不可用？
A: 确认 VirtualBox 网络设为 NAT，重启虚拟机再试。

### Q: 虚拟机分辨率太低/鼠标不流畅？
A: 安装 Guest Additions 可解决。

### Q: 安装包下载慢？
A: 安装完成后将 yum/dnf 源切换为中科大镜像（见 6.4 节）。
