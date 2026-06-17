# 实验4：搭建 DHCP 和 DNS 服务器

## 实验目的

使用 dnsmasq 一站式搭建 DHCP 和 DNS 服务器，实现局域网 IP 地址动态分配和域名解析。

## 实验要求

1. 安装 dnsmasq
2. 配置 DNS 解析
3. 配置 DHCP 地址池
4. 验证 DNS 解析和 DHCP 分配

## 操作步骤

### 1. 执行安装脚本

```bash
sudo bash setup.sh
```

### 2. 验证配置

```bash
sudo bash verify.sh
```

### 3. 客户端测试

在另一台虚拟机上将网卡设为 DHCP 模式，验证能否获取 IP。

## 验收标准

- dnsmasq 服务正常运行
- nslookup 可解析测试域名
- DHCP 配置段存在且格式正确
