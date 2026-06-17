# Rocky Linux 9.8 安装与实训指南

## 目录

- [系统安装指南](#系统安装指南)
- [8 个实训实验](#8-个实训实验)
  - [实验1：YUM 配置国内源](labs/lab1_国内源/README.md)
  - [实验2：搭建 VPN 服务器](labs/lab2_VPN/README.md)
  - [实验3：搭建邮件服务器](labs/lab3_邮件/README.md)
  - [实验4：搭建 DHCP 和 DNS 服务器](labs/lab4_DHCP_DNS/README.md)
  - [实验5：搭建 Web 服务器](labs/lab5_Web/README.md)
  - [实验6：搭建 Samba 服务器](labs/lab6_Samba/README.md)
  - [实验7：搭建代理服务器](labs/lab7_代理/README.md)
  - [实验8：搭建 NAT 服务器](labs/lab8_NAT/README.md)

---

# 系统安装指南

## 1. 为什么选 Rocky Linux 9.8

- Rocky Linux 是 RHEL（Red Hat Enterprise Linux）的下游发行版，**100% 兼容 RHEL**
- 9.8 是 9.x 系列最新稳定版，软件包较新
- 作为 CentOS 的替代品，生态成熟，命令与原实训完全兼容

## 2. 三种 ISO 对比

| ISO 类型 | 文件大小 | 安装方式 | 适用场景 |
|----------|----------|----------|----------|
| **Boot ISO** | ~1.4 GB | 网络安装，按需下载包 | **推荐** — 实验、虚拟机测试 |
| **DVD ISO** | ~14.2 GB | 完整离线安装 | 无网络环境、批量部署 |
| **Minimal ISO** | ~2.6 GB | 离线最小化安装 | 纯命令行服务器 |

## 3. 下载

### 中科大镜像源（推荐）

```
https://mirrors.ustc.edu.cn/rocky/9.8/isos/x86_64/Rocky-9.8-x86_64-boot.iso
```

- 文件大小：约 1.38 GB
- 国内访问速度快

## 4. VirtualBox 安装

### 下载

| 来源 | 地址 |
|------|------|
| 官方 | https://www.virtualbox.org/wiki/Downloads |
| 中科大镜像 | https://mirrors.ustc.edu.cn/virtualbox/ |

选择对应系统安装包，Windows 下载文件名类似 `VirtualBox-7.0.24-167081-Win.exe`。

### 安装

双击安装包，按默认选项完成即可（网卡驱动、USB 驱动均勾选）。

## 5. VirtualBox 虚拟机配置

| 配置项 | 建议值 |
|--------|--------|
| 类型 | Linux / Red Hat (64-bit) |
| 内存 | 2048 MB 以上 |
| CPU | 2 核以上 |
| 虚拟硬盘 | 20 GB 动态分配 |
| 网络 | NAT（默认）+ Host-Only（实验内网） |

### 创建步骤

1. VirtualBox → 新建
2. 名称：`Rocky-9.8`，类型：`Linux`，版本：`Red Hat (64-bit)`
3. 内存：建议 `2048 MB`
4. 虚拟硬盘：`现在创建虚拟硬盘` → VDI → 动态分配 → 20 GB
5. 创建完成后 → 设置 → 存储 → 选择 Boot ISO 镜像
6. 网络：默认 NAT，需要时添加 Host-Only 网卡

### 实验用多虚拟机建议

| 虚拟机 | 角色 | 网卡 |
|--------|------|------|
| server | 承载各实验服务 | NAT + Host-Only |
| client | 测试客户端 | Host-Only |

## 6. 安装流程

### 5.1 启动安装

启动虚拟机，选择 **Install Rocky Linux 9.8**

### 5.2 语言

选择 `English (United States)` 或 `中文（简体）`

### 5.3 安装目标

Storage Configuration 选 `Automatic`

### 5.4 软件选择

- **Minimal Install** — 纯命令行（实验推荐）
- **Server with GUI** — 带 GNOME 桌面

### 5.5 用户设置

- 设置 Root Password
- 创建普通用户，勾选 `Make this user administrator`

### 5.6 开始安装

点击 **Begin Installation**，完成后重启。

## 7. 安装后配置

```bash
# 更新系统
yum update -y

# 安装常用工具
yum install -y vim git curl wget net-tools bind-utils

# 安装 Guest Additions（可选，改善虚拟机体验）
yum install -y gcc kernel-devel kernel-headers elfutils-libelf-devel
# 然后挂载 VBoxGuestAdditions.iso 运行
```

---

# 8 个实训实验

## 快速入口

每个实验目录包含三个文件：

| 文件 | 作用 |
|------|------|
| `README.md` | 实验目的、步骤说明 |
| `setup.sh` | 一键安装配置脚本 |
| `verify.sh` | 验收检查脚本（教师用） |

## 实验列表

### [实验1：YUM 配置国内源](labs/lab1_国内源/README.md)

将默认国外源替换为阿里云镜像，提升下载速度。

```bash
cd labs/lab1_国内源
sudo bash setup.sh      # 配置
sudo bash verify.sh     # 验收
```

**验收检测**：repo 文件存在、阿里云仓库已启用、makecache 正常、软件包搜索正常

### [实验2：搭建 VPN 服务器](labs/lab2_VPN/README.md)

使用 OpenVPN + easy-rsa 搭建 VPN 服务器。

```bash
cd labs/lab2_VPN
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：服务运行、1194/udp 监听、tun0 网卡存在、配置文件完整

### [实验3：搭建邮件服务器](labs/lab3_邮件/README.md)

使用 Postfix 通过 QQ 邮箱 SMTP 中继发送邮件。

```bash
cd labs/lab3_邮件
sudo bash setup.sh      # 会提示输入 QQ 邮箱和授权码
sudo bash verify.sh
```

**验收检测**：postfix 运行、QQ 中继已配置、sasl_passwd 存在、配置语法正确

### [实验4：搭建 DHCP 和 DNS 服务器](labs/lab4_DHCP_DNS/README.md)

使用 dnsmasq 一站式搭建 DHCP + DNS。

```bash
cd labs/lab4_DHCP_DNS
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：dnsmasq 运行、DHCP 地址池已配、域名配置正确、本地 DNS 解析正常

### [实验5：搭建 Web 服务器](labs/lab5_Web/README.md)

Apache 基于域名的虚拟主机，一个 IP 两个网站。

```bash
cd labs/lab5_Web
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：httpd/named 运行、curl test-web1.com 返回 "this is web1"、test-web2.com 返回 "this is web2"

### [实验6：搭建 Samba 服务器](labs/lab6_Samba/README.md)

多用户多组分级权限文件共享。

```bash
cd labs/lab6_Samba
sudo bash setup.sh       # 所有 Samba 用户默认密码 123456
sudo bash verify.sh
```

**验收检测**：smb 运行、7 个共享均定义、各用户目录存在、权限矩阵正确生效

### [实验7：搭建代理服务器](labs/lab7_代理/README.md)

Squid HTTP 正向代理，端口 8080。

```bash
cd labs/lab7_代理
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：squid 运行、8080 端口监听、`curl -x` 可访问外网

### [实验8：搭建 NAT 服务器](labs/lab8_NAT/README.md)

iptables NAT + 防火墙，内网通过服务器上网。

```bash
cd labs/lab8_NAT
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：ip_forward=1、iptables 运行、FORWARD 规则存在、MASQUERADE 规则存在、规则已持久化

---

## 验收脚本使用说明

所有 `verify.sh` 输出格式统一：

```
[PASS] 检查项描述
[FAIL] 检查项描述
[WARN] 检查项描述

=== 结果：N 通过, M 失败 ===
```

- 全部 PASS → `exit 0`（验收通过）
- 有 FAIL → `exit 1`（验收不通过）

可批量检查所有实验：

```bash
for lab in labs/lab*; do
    echo "=== $lab ==="
    sudo bash "$lab/verify.sh" && echo "PASS" || echo "FAIL"
    echo ""
done
```
