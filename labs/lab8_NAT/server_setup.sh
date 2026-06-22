#!/bin/bash
set -e

echo "=== 实验8：【NAT 服务器/网关端】配置 ==="

# 自动检测网卡：有默认路由的为外网(WAN)，另一个为内网(LAN)
WAN_IF=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
ALL_IFS=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | tr '\n' ' ')

if [ -z "$WAN_IF" ]; then
    echo "[WARN] 未检测到默认路由，使用默认网卡名 enp0s8(WAN) / enp0s3(LAN)"
    WAN_IF="enp0s8"
fi

# 找第一张不等于 WAN_IF 的网卡作为 LAN
for iface in $ALL_IFS; do
    if [ "$iface" != "$WAN_IF" ]; then
        LAN_IF="$iface"
        break
    fi
done

if [ -z "$LAN_IF" ]; then
    echo "[WARN] 未检测到第二张网卡，使用默认 enp0s3"
    LAN_IF="enp0s3"
fi

echo "外网网卡: $WAN_IF"
echo "内网网卡: $LAN_IF"

echo "[1/5] 安装 iptables-services ..."
yum install -y iptables-services

echo "[2/5] 启用 IP 转发 ..."
if ! grep -q "net.ipv4.ip_forward = 1" /etc/sysctl.conf 2>/dev/null; then
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1

echo "[3/5] 停止 firewalld，启用 iptables ..."
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
systemctl enable iptables
systemctl start iptables

echo "[4/5] 配置 NAT 和防火墙规则 ..."

# 清空现有规则
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -X

# 默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许 lo 回环
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 允许已建立和相关的连接
iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# NAT 转发规则
iptables -A FORWARD -i "$LAN_IF" -o "$WAN_IF" -j ACCEPT

# 内网允许访问的服务
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -p tcp --dport 80  -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -p tcp --dport 25  -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -p tcp --dport 110 -j ACCEPT

# SNAT 地址伪装
iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE

# 保存规则
iptables-save > /etc/sysconfig/iptables

echo "[5/5] 完成后检查规则 ..."
iptables -L -v -n
echo ""
echo "=== 实验8 服务器端安装完成 ==="
echo "检查规则: iptables -L -v -n"
echo "检查NAT:  iptables -t nat -L -v -n"
echo ""
echo "下一步：客户端请在另一台 VM 运行（参数为本机的 Host-Only IP）:"
echo "  bash client_setup.sh <本机Host-OnlyIP>"
echo "例如本机 Host-Only IP 为 192.168.56.101 时："
echo "  bash client_setup.sh 192.168.56.101"
