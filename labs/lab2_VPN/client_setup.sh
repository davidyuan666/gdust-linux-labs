#!/bin/bash
set -e

SERVER_IP="${1}"

if [ -z "$SERVER_IP" ]; then
    echo "用法: sudo bash client_setup.sh <服务器IP>"
    echo "示例: sudo bash client_setup.sh 192.168.56.101"
    exit 1
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
EOF

systemctl enable openvpn-client@client
systemctl start openvpn-client@client

echo ""
echo "=== 客户端配置完成 ==="
echo "等待 5 秒建立连接后执行 client_verify.sh 验证"
