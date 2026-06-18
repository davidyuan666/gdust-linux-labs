# Rocky Linux 9.8 安装与实训指南

## 目录

- [系统安装指南](#系统安装指南)
- [8 个实训实验](#8-个实训实验)
  - [实验1：YUM 配置国内源](#实验1yum-配置国内源)
  - [实验2：搭建 VPN 服务器](#实验2搭建-vpn-服务器)
  - [实验3：搭建邮件服务器](#实验3搭建邮件服务器)
  - [实验4：搭建 DHCP 和 DNS 服务器](#实验4搭建-dhcp-和-dns-服务器)
  - [实验5：搭建 Web 服务器](#实验5搭建-web-服务器)
  - [实验6：搭建 Samba 服务器](#实验6搭建-samba-服务器)
  - [实验7：搭建代理服务器](#实验7搭建代理服务器)
  - [实验8：搭建 NAT 服务器](#实验8搭建-nat-服务器)

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
| 网络 | **NAT + Host-Only 双网卡**（外网+固定IP SSH）|

### 创建步骤

1. VirtualBox → 新建
2. 名称：`Rocky-9.8`，类型：`Linux`，版本：`Red Hat (64-bit)`
3. 内存：建议 `2048 MB`
4. 虚拟硬盘：`现在创建虚拟硬盘` → VDI → 动态分配 → 20 GB
5. 创建完成后 → 设置 → 存储 → 选择 Boot ISO 镜像
6. 网络：**网卡1 NAT + 网卡2 Host-Only**（混杂模式均拒绝）

### 实验用多虚拟机建议

| 虚拟机 | 角色 | 网卡 |
|--------|------|------|
| server | 承载各实验服务 | NAT + Host-Only |
| client | 测试客户端 | NAT + Host-Only |

> **实验 4（DHCP + DNS）特殊说明**：使用**单机三网卡自闭环**方案，无需第二台 VM。
> 给 server 新增 NIC3（内部网络模式），dnsmasq 绑定内网 IP `10.100.0.1`，
> NIC3 通过 dhclient 向自己获取 DHCP 地址。详见 [实验 4](#实验4搭建-dhcp-和-dns-服务器)。

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

> **注意**：Rocky 9 默认 repo 包含 `$contentdir` 变量（展开为 `/pub/rocky`），
> 国内镜像无此路径，直接替换域名会导致 404。**建议先按实验1配置阿里云源**，
> 或手动修复应急：
>
> ```bash
> sudo sed -i 's|\$contentdir|rocky|g' /etc/yum.repos.d/rocky*.repo
> ```
>
> 修复后才能正常执行以下命令。

```bash
# 更新系统
yum update -y

# 安装常用工具
yum install -y vim git curl wget net-tools bind-utils

# 安装 Guest Additions（可选，改善虚拟机体验）
yum install -y gcc kernel-devel kernel-headers elfutils-libelf-devel
# 然后挂载 VBoxGuestAdditions.iso 运行
```

## 8. SSH 远程访问

### 启用 SSH

```bash
yum install -y openssh-server
systemctl enable sshd --now
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
```

### 网络配置（NAT + Host-Only 双网卡）

| 网卡 | 连接方式 | 作用 |
|------|---------|------|
| 网卡1 | **NAT** | 虚拟机访问外网 |
| 网卡2 | **Host-Only** | Windows SSH 连接，固定 IP，不受 WiFi 影响 |

> WiFi 下不推荐桥接模式，WiFi 桥接不支持完整 DHCP 透传，常导致 IPv4 不可用。

VirtualBox → 设置 → 网络（需关机状态）：

- 网卡1：启用 ☑ → NAT → 混杂模式：拒绝
- 网卡2：启用 ☑ → Host-Only → 混杂模式：拒绝

虚拟机启动后：

```bash
ip a | grep 192.168.56
```

Windows 终端（PowerShell / CMD）连接：

```bash
ssh 用户名@192.168.56.101
```

### 双网卡故障排查

如果 `ip a` 显示第二张网卡（如 `enp0s8`）状态 `UP` 但没有 IPv4 地址，
说明 NetworkManager 未自动管理该接口，手动创建连接即可：

```bash
sudo nmcli connection add type ethernet ifname enp0s8 con-name nat autoconnect yes
```

### 网卡命名说明

Rocky Linux 9 使用 Predictable Network Interface Names，网卡名形如：

| VirtualBox 网卡 | Rocky 9 接口名 |
|:---:|:---:|
| 网卡1 | `enp0s3` |
| 网卡2 | `enp0s8` |

与旧版 `eth0`/`eth1` 不同，实验脚本中如遇网卡名请以 `ip a` 实际输出为准。

> 实验8（NAT）需要双网卡：一张外网（NAT，enp0s8）+ 一张内网（Host-Only，enp0s3）。

# 8 个实训实验

## 快速入口

每个实验目录包含安装配置脚本和验收脚本，详细说明和原理请参阅 [实训指导书 PDF](labs/lab_guide.pdf)。

| 文件 | 作用 |
|------|------|
| `setup.sh` / `server_setup.sh` / `client_setup.sh` | 一键安装配置脚本 |
| `verify.sh` / `server_verify.sh` / `client_verify.sh` | 验收检查脚本 |

## 实验列表

### 实验1：YUM 配置国内源

将默认国外源替换为阿里云镜像，提升下载速度。

```bash
cd labs/lab1_yum_repo
sudo bash setup.sh      # 配置
sudo bash verify.sh     # 验收
```

**验收检测**：repo 文件存在、阿里云仓库已启用、makecache 正常、软件包搜索正常

### 实验2：搭建 VPN 服务器

使用 OpenVPN + easy-rsa 搭建 VPN，server + client 双机协同（需 2 台 VM）。

```bash
cd labs/lab2_VPN
# 服务端（生成证书 + 启动服务）
sudo bash server_setup.sh
sudo bash server_verify.sh

# 客户端（可自动发现服务端 IP，也可手动传入）
sudo bash client_setup.sh
sudo bash client_verify.sh
```

**验收检测**：服务端 1194/udp 监听、tun0 创建；客户端 ping 10.8.0.1 通、tun0 路由推送生效

### 实验3：搭建邮件服务器

使用 Postfix 通过 QQ/163 邮箱 SMTP 中继发送邮件。

```bash
cd labs/lab3_email
sudo bash setup.sh      # 会提示输入 QQ 邮箱和授权码
sudo bash verify.sh
```

**验收检测**：postfix 运行、QQ 中继已配置、sasl_passwd 存在、配置语法正确

### 实验4：搭建 DHCP 和 DNS 服务器

使用 dnsmasq 一站式搭建 DHCP + DNS，**单机自闭环**无需第二台虚拟机。

#### 网卡架构

给 server VM 新增 **第三张网卡（内部网络模式）**，三张网卡各司其职：

| 网卡 | 连接方式 | IP 来源 | 用途 |
|------|---------|---------|------|
| NIC1 (enp0s3) | NAT | VirtualBox DHCP | 访问外网（yum install、DNS 转发） |
| NIC2 (enp0s8) | Host-Only | 静态 192.168.56.x | Windows SSH 连接 |
| NIC3 (enp0s9，新增) | **内部网络** | 静态 10.100.0.1/24 | dnsmasq DHCP + DNS 验证 |

> NIC3 为内部网络模式（**不是** Host-Only），与 NIC1/NIC2 完全隔离。
> dnsmasq 绑定 `10.100.0.1`，DHCP 池 `10.100.0.50-150`，NIC3 通过 dhclient 向自己获取地址。

#### VirtualBox 操作

1. **关闭 VM** → 设置 → 网络 → 网卡 3 → 启用
2. 连接方式选择：**内部网络 (Internal Network)**
3. 名称填写：`intnet-dhcp`（可自定义）
4. 启动 VM

#### 运行

```bash
cd labs/lab4_DHCP_DNS
sudo bash setup.sh      # 自动发现 NIC3、配置静态 IP、启动 dnsmasq、dhclient 验证
sudo bash verify.sh
```

**验收检测**：dnsmasq 运行、DHCP 地址池已配、域名配置正确、内部网络网卡已配、DHCP 租约成功、本地 DNS 解析正常、配置语法正确

### 实验5：搭建 Web 服务器

Apache 基于域名的虚拟主机，一个 IP 两个网站。

```bash
cd labs/lab5_Web
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：httpd/named 运行、curl test-web1.com 返回 "this is web1"、test-web2.com 返回 "this is web2"

#### 从 Windows 宿主访问

VM 的 Host-Only 网卡与 Windows 互通，可直接通过浏览器访问：

**PowerShell 直接测试**：
```powershell
curl -H "Host: www.test-web1.com" http://192.168.56.101/
curl -H "Host: www.test-web2.com" http://192.168.56.101/
```

**浏览器访问**（需添加 hosts 映射）：
编辑 `C:\Windows\System32\drivers\etc\hosts`（管理员权限），添加：
```
192.168.56.101  www.test-web1.com
192.168.56.101  www.test-web2.com
```
然后浏览器直接访问 `http://www.test-web1.com` 和 `http://www.test-web2.com`。

### 实验6：搭建 Samba 服务器

多用户多组分级权限文件共享。

```bash
cd labs/lab6_Samba
sudo bash setup.sh       # 所有 Samba 用户默认密码 123456
sudo bash verify.sh
```

**验收检测**：smb 运行、7 个共享均定义、各用户目录存在、权限矩阵正确生效

### 实验7：搭建代理服务器

Squid HTTP 正向代理，端口 8080。

```bash
cd labs/lab7_proxy
sudo bash setup.sh
sudo bash verify.sh
```

**验收检测**：squid 运行、8080 端口监听、curl -x 可访问外网

### 实验8：搭建 NAT 服务器

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
    for verify in "$lab"/*verify.sh; do
        echo "=== $verify ==="
        sudo bash "$verify" && echo "PASS" || echo "FAIL"
        echo ""
    done
done
```
