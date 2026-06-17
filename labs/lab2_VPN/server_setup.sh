#!/bin/bash
set -e

echo "=== 实验2：搭建 VPN 服务器（服务端）==="

echo "[0/6] 清理旧配置，支持重复执行 ..."
systemctl stop openvpn-server@server 2>/dev/null || true
systemctl disable openvpn-server@server 2>/dev/null || true
rm -rf /opt/easy-rsa/pki
rm -rf /etc/openvpn/server

echo "[1/6] 安装依赖 ..."
yum install -y epel-release
yum install -y openvpn easy-rsa wget

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
set_var EASYRSA_REQ_PROVINCE "Beijing"
set_var EASYRSA_REQ_CITY "Beijing"
set_var EASYRSA_REQ_ORG "example"
set_var EASYRSA_REQ_EMAIL "admin@example.com"
set_var EASYRSA_NS_SUPPORT "yes"
EOF

echo "[3/6] 生成证书 ..."
./easyrsa init-pki
echo "" | ./easyrsa build-ca nopass
echo "" | ./easyrsa gen-req server nopass
./easyrsa --batch sign-req server server
openssl ecparam -genkey -name prime256v1 -out /opt/easy-rsa/pki/ec.pem
echo "" | ./easyrsa gen-req client nopass
./easyrsa --batch sign-req client client

echo "[4/6] 写入服务端配置 ..."
mkdir -p /etc/openvpn/server
cat > /etc/openvpn/server/server.conf << 'EOF'
port 1194
proto udp
dev tun
ca /opt/easy-rsa/pki/ca.crt
cert /opt/easy-rsa/pki/issued/server.crt
key /opt/easy-rsa/pki/private/server.key
dh none
ecdh-curve prime256v1
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

echo "[6/6] 启动服务并开放证书读权限 ..."
systemctl enable openvpn-server@server
systemctl start openvpn-server@server
chmod -R o+rX /opt/easy-rsa/pki

echo ""
echo "=== 服务端安装完成 ==="
echo "客户端证书位于："
echo "  CA:   /opt/easy-rsa/pki/ca.crt"
echo "  Cert: /opt/easy-rsa/pki/issued/client.crt"
echo "  Key:  /opt/easy-rsa/pki/private/client.key"
echo ""
echo "在客户端执行 client_setup.sh（需传入本机 IP）"
