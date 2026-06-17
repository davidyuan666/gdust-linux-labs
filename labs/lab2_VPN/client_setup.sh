#!/bin/bash
set -e

SERVER_IP="${1}"

if [ -z "$SERVER_IP" ]; then
    echo "[自动发现] 扫描 Host-Only 网络中运行 VPN 服务端的设备 ..."
    SELF_IP=$(ip -4 a show enp0s3 2>/dev/null | grep -oP '192\.168\.56\.\d+' | head -1)
    [ -z "$SELF_IP" ] && SELF_IP="192.168.56.102"
    echo "  本机 IP: $SELF_IP"
    for cand in 192.168.56.101 192.168.56.100 192.168.56.1; do
        [ "$cand" = "$SELF_IP" ] && continue
        echo -n "  探测 $cand ... "
        if ping -c 1 -W 1 "$cand" &>/dev/null; then
            echo "通"
            SERVER_IP="$cand"
            break
        else
            echo "不通"
        fi
    done
    if [ -z "$SERVER_IP" ]; then
        echo ""
        echo "未找到服务端，请手动指定 IP：sudo bash client_setup.sh <服务器IP>"
        exit 1
    fi
fi

SSH_USER="${SUDO_USER:-$USER}"

echo "=== 实验2：搭建 VPN 服务器（客户端）==="
echo "连接目标: $SERVER_IP  (用户: $SSH_USER)"

echo "[0/3] 清理旧配置，支持重复执行 ..."
systemctl stop openvpn-client@client 2>/dev/null || true
systemctl disable openvpn-client@client 2>/dev/null || true
rm -rf /etc/openvpn/client

echo "[1/3] 安装 OpenVPN ..."
yum install -y openvpn

echo "[2/3] 从服务端获取证书 ..."
mkdir -p /etc/openvpn/client
scp "${SSH_USER}@${SERVER_IP}:/opt/easy-rsa/pki/ca.crt"           /etc/openvpn/client/
scp "${SSH_USER}@${SERVER_IP}:/opt/easy-rsa/pki/issued/client.crt" /etc/openvpn/client/
scp "${SSH_USER}@${SERVER_IP}:/opt/easy-rsa/pki/private/client.key" /etc/openvpn/client/

echo "[3/3] 写入客户端配置并启动 ..."
cat > /etc/openvpn/client/client.conf << EOF
client
dev tun
proto udp
remote ${SERVER_IP} 1194
ca /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/client.crt
key /etc/openvpn/client/client.key
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
comp-lzo
pull-filter ignore "route 192.168.56.0"
EOF

systemctl enable openvpn-client@client
systemctl start openvpn-client@client

echo ""
echo "=== 客户端配置完成 ==="
echo "等待 5 秒建立连接后执行 client_verify.sh 验证"
