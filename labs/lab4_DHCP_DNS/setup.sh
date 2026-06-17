#!/bin/bash
set -e

echo "=== 实验4：搭建 DHCP 和 DNS 服务器 ==="

SERVER_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[ -z "$SERVER_IP" ] && SERVER_IP="192.168.56.10"
echo "检测到服务器 IP: $SERVER_IP"

echo "[1/4] 安装 dnsmasq ..."
yum install -y dnsmasq

echo "[2/4] 配置 dnsmasq ..."
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak.$(date +%Y%m%d)
cat > /etc/dnsmasq.conf << EOF
listen-address=127.0.0.1,${SERVER_IP}
bind-interfaces
domain=tecmint.lan
server=223.5.5.5
server=223.6.6.6
address=/tecmint.lan/127.0.0.1
address=/tecmint.lan/${SERVER_IP}
cache-size=150
dhcp-range=192.168.56.50,192.168.56.150,12h
dhcp-option=3,192.168.56.1
dhcp-option=6,${SERVER_IP}
EOF

echo "[3/4] 配置防火墙 ..."
firewall-cmd --permanent --add-service=dns 2>/dev/null || true
firewall-cmd --permanent --add-service=dhcp 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

echo "[4/4] 启动服务 ..."
systemctl enable dnsmasq
systemctl restart dnsmasq

echo ""
echo "=== 实验4 安装完成 ==="
echo "测试 DNS: nslookup tecmint.lan ${SERVER_IP}"
echo "测试外网: nslookup www.baidu.com ${SERVER_IP}"
