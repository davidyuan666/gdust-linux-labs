#!/bin/bash
set -e

echo "=== 实验7：搭建代理服务器 ==="

echo "[1/3] 安装 Squid ..."
yum install -y squid

echo "[2/3] 配置 Squid ..."
cp /etc/squid/squid.conf /etc/squid/squid.conf.bak.$(date +%Y%m%d)
cat > /etc/squid/squid.conf << 'EOF'
acl localnet src 0.0.0.1-0.255.255.255
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost

http_port 8080

coredump_dir /var/spool/squid

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
EOF

echo "[3/3] 启动服务 ..."
systemctl enable squid
systemctl restart squid

echo ""
echo "=== 实验7 安装完成 ==="
echo "测试: curl -x http://localhost:8080 http://www.baidu.com"
