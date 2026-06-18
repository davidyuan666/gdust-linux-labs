#!/bin/bash
set -e

echo "=== 实验4：搭建 DHCP 和 DNS 服务器 ==="

SERVER_IP="10.100.0.1"
echo "内部网络 IP: ${SERVER_IP}"

echo "[1/5] 安装 dnsmasq ..."
yum install -y dnsmasq

echo "[2/5] 配置内部网络网卡 (NIC3) ..."
NIC3=$(ip -o link show | grep -v 'lo' | awk -F': ' '{print $2}' | while read iface; do
    ip addr show "$iface" 2>/dev/null | grep -q 'inet ' || echo "$iface"
done | head -1)

if [ -z "$NIC3" ]; then
    echo "  无法自动发现未配置的网卡，尝试常见的 NIC3 接口名 ..."
    for try in enp0s9 enp0s10 enp0s16 ens9 ens10; do
        if ip link show "$try" &>/dev/null && ! ip addr show "$try" 2>/dev/null | grep -q 'inet '; then
            NIC3="$try"
            break
        fi
    done
fi

if [ -z "$NIC3" ]; then
    echo "  无法发现 NIC3，请确认 VM 已添加第三张网卡（类型: 内部网络）"
    echo "  尝试使用默认接口名 enp0s9 ..."
    NIC3="enp0s9"
fi

echo "  NIC3 接口: ${NIC3}"

ip link set "$NIC3" up 2>/dev/null || true
nmcli connection delete "$NIC3" 2>/dev/null || true
nmcli connection add type ethernet ifname "$NIC3" con-name "dhcp-intnet" ip4 "${SERVER_IP}/24" autoconnect yes 2>/dev/null || {
    ip addr add "${SERVER_IP}/24" dev "$NIC3" 2>/dev/null || true
    ip link set "$NIC3" up
}

echo "  NIC3 静态 IP: ${SERVER_IP}/24"

echo "[3/5] 配置 dnsmasq ..."
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak.$(date +%Y%m%d)
cat > /etc/dnsmasq.conf << EOF
listen-address=${SERVER_IP}
bind-interfaces
domain=tecmint.lan
server=223.5.5.5
server=223.6.6.6
address=/tecmint.lan/${SERVER_IP}
cache-size=150
dhcp-range=${SERVER_IP%.*}.50,${SERVER_IP%.*}.150,12h
dhcp-option=3,${SERVER_IP}
dhcp-option=6,${SERVER_IP}
dhcp-leasefile=/var/lib/misc/dnsmasq.leases
EOF

echo "[4/5] 配置防火墙 ..."
firewall-cmd --permanent --add-service=dns 2>/dev/null || true
firewall-cmd --permanent --add-service=dhcp 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

echo "[5/5] 启动服务并验证 DHCP 自获取 ..."
systemctl enable dnsmasq
systemctl restart dnsmasq

sleep 2

echo "  通过 NIC3 发起 DHCP 请求 ..."
dhclient -v "$NIC3" 2>/dev/null || dhclient "$NIC3" 2>/dev/null || true
sleep 1

if ip addr show "$NIC3" | grep -q "10.100.0"; then
    DHCP_IP=$(ip addr show "$NIC3" | grep -oP 'inet \K10\.100\.0\.\d+')
    echo "  NIC3 DHCP 获取 IP: ${DHCP_IP}"
else
    echo "  [WARN] NIC3 未通过 DHCP 获取到 10.100.0.x 地址，请检查 $NIC3 是否配置为内部网络模式"
fi

echo ""
echo "=== 实验4 安装完成 ==="
echo "测试 DNS: nslookup tecmint.lan ${SERVER_IP}"
echo "测试外网: nslookup www.baidu.com ${SERVER_IP}"
echo "NIC3 接口: ${NIC3} (内部网络模式，IP: ${DHCP_IP:-未获取})"
