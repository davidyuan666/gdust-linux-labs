# 实验8：搭建 NAT 服务器

## 实验目的

使用 iptables 配置 NAT（网络地址转换）服务器，使内网主机通过该服务器访问外网，同时配置防火墙规则限制访问。

## 实验要求

1. 安装 iptables-services
2. 启用 IP 转发
3. 配置 SNAT / MASQUERADE 规则
4. 配置防火墙只允许 Web、DNS、邮件服务
5. 验证 NAT 功能

## 前置条件

- 服务器至少有两张网卡（一张内网 eth1、一张外网 eth0）

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

- ip_forward = 1 已启用
- iptables MASQUERADE 规则存在
- iptables FORWARD 规则存在
- 内网客户端可通过 NAT 服务器访问外网
