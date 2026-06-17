#!/bin/bash
set -e

echo "=== 实验2：搭建 OpenVPN 服务器 ==="

echo "[1/6] 安装依赖 ..."
dnf install -y epel-release
dnf install -y openvpn easy-rsa wget

echo "[2/6] 配置 easy-rsa ..."
EASYRSA_DIR="/opt/easy-rsa"
if [ ! -d "$EASYRSA_DIR" ]; then
    mkdir -p "$EASYRSA_DIR"
fi
cd "$EASYRSA_DIR"
cp -a /usr/share/easy-rsa/3/* ./ 2>/dev/null || cp -a /usr/share/easy-rsa/3.*/* ./ 2>/dev/null

cat > vars << 'EOF'
if [ -z "$EASYRSA_CALLER" ]; then
    echo "You appear to be sourcing an Easy-RSA 'vars' file." >&2
    return 1
fi
set_var EASYRSA_DN "cn_only"
set_var EASYRSA_REQ_COUNTRY "CN"
set_var EASYRSA_REQ_PROVINCE "GuangDong"
set_var EASYRSA_REQ_CITY "DongGuan"
set_var EASYRSA_REQ_ORG "school"
set_var EASYRSA_REQ_EMAIL "admin@school.edu"
set_var EASYRSA_NS_SUPPORT "yes"
EOF

echo "[3/6] 生成证书 ..."
./easyrsa init-pki
echo "" | ./easyrsa build-ca nopass
echo "" | ./easyrsa gen-req server nopass
echo "yes" | ./easyrsa sign-req server server
./easyrsa gen-dh
echo "" | ./easyrsa gen-req client nopass
echo "yes" | ./easyrsa sign-req client client

echo "[4/6] 写入服务端配置 ..."
mkdir -p /etc/openvpn/server
cat > /etc/openvpn/server/server.conf << 'EOF'
port 1194
proto udp
dev tun
ca /opt/easy-rsa/pki/ca.crt
cert /opt/easy-rsa/pki/issued/server.crt
key /opt/easy-rsa/pki/private/server.key
dh /opt/easy-rsa/pki/dh.pem
server 10.8.0.0 255.255.255.0
push "route 192.168.56.0 255.255.255.0"
ifconfig-pool-persist ipp.txt
keepalive 10 120
max-clients 100
status openvpn-status.log
log /var/log/openvpn.log
verb 3
client-to-client
persist-key
persist-tun
duplicate-cn
comp-lzo
EOF

echo "[5/6] 配置防火墙 ..."
firewall-cmd --permanent --add-port=1194/udp 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

echo "[6/6] 启动服务 ..."
systemctl enable openvpn-server@server
systemctl start openvpn-server@server

echo ""
echo "=== 实验2 安装完成 ==="
echo "客户端证书位置："
echo "  CA:   /opt/easy-rsa/pki/ca.crt"
echo "  Cert: /opt/easy-rsa/pki/issued/client.crt"
echo "  Key:  /opt/easy-rsa/pki/private/client.key"
