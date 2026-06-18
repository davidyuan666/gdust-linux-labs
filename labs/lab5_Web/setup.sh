#!/bin/bash
set -e

echo "=== 实验5：搭建 Web 服务器 ==="

SERVER_IP=$(ip -o -4 addr show | grep '192\.168\.56\.' | awk '{print $4}' | cut -d/ -f1 | head -1)
[ -z "$SERVER_IP" ] && SERVER_IP="192.168.56.101"
echo "服务器 IP (Host-Only): $SERVER_IP"

echo "[1/6] 安装 Apache 和 BIND ..."
yum install -y httpd bind

echo "[2/6] 创建虚拟主机目录 ..."
mkdir -p /var/www/test-web1 /var/www/test-web2
echo "this is web1" > /var/www/test-web1/index.html
echo "this is web2" > /var/www/test-web2/index.html

echo "[3/6] 配置 DNS 区域 ..."

# 移除旧的 zone 定义（支持重复运行）
sed -i '/^# ===== lab5 zones begin =====$/,/^# ===== lab5 zones end =====$/d' /etc/named.conf 2>/dev/null || true

cat >> /etc/named.conf << 'EOF'
# ===== lab5 zones begin =====
zone "test-web1.com" IN {
    type master;
    file "web1.com.zone";
};
zone "test-web2.com" IN {
    type master;
    file "web2.com.zone";
};
# ===== lab5 zones end =====
EOF

cat > /var/named/web1.com.zone << EOF
\$TTL 1D
@       IN SOA  @ rname.invalid. (
                    0       ; serial
                    1D      ; refresh
                    1H      ; retry
                    1W      ; expire
                    3H )    ; minimum
@       IN NS   www.test-web1.com.
www     IN A    ${SERVER_IP}
EOF

cat > /var/named/web2.com.zone << EOF
\$TTL 1D
@       IN SOA  @ rname.invalid. (
                    0       ; serial
                    1D      ; refresh
                    1H      ; retry
                    1W      ; expire
                    3H )    ; minimum
@       IN NS   www.test-web2.com.
www     IN A    ${SERVER_IP}
EOF

chown named:named /var/named/web1.com.zone /var/named/web2.com.zone

echo "[4/6] 配置 Apache 虚拟主机 ..."
cat > /etc/httpd/conf.d/vhosts.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@test-web1.com
    DocumentRoot /var/www/test-web1
    ServerName www.test-web1.com
    DirectoryIndex index.html
    ErrorLog logs/test-web1.error_log
    CustomLog logs/test-web1.access_log common
</VirtualHost>

<VirtualHost *:80>
    ServerAdmin admin@test-web2.com
    DocumentRoot /var/www/test-web2
    ServerName www.test-web2.com
    DirectoryIndex index.html
    ErrorLog logs/test-web2.error_log
    CustomLog logs/test-web2.access_log common
</VirtualHost>
EOF

echo "[5/6] 配置防火墙 ..."
firewall-cmd --permanent --add-service=http 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

echo "[6/6] 启动服务 ..."
systemctl stop named 2>/dev/null || true
systemctl stop httpd 2>/dev/null || true
systemctl enable httpd named
systemctl start httpd || {
    echo "  [WARN] httpd 启动失败，诊断中..."
    journalctl -xeu httpd --no-pager -n 5 2>/dev/null || true
    httpd -t 2>&1 || true
}
systemctl start named || {
    echo "  [WARN] named 启动失败，诊断中..."
    journalctl -xeu named --no-pager -n 10 2>/dev/null || true
    named-checkconf -z /etc/named.conf 2>&1 || true
    echo "  Apache 不受影响，可继续使用"
}

echo ""
echo "=== 实验5 安装完成 ==="
echo "测试: curl -H 'Host: www.test-web1.com' http://${SERVER_IP}/"
echo "      curl -H 'Host: www.test-web2.com' http://${SERVER_IP}/"
echo ""
echo "从 Windows 宿主访问:"
echo "  PowerShell: curl -H 'Host: www.test-web1.com' http://${SERVER_IP}/"
echo "  浏览器: 修改 C:\\Windows\\System32\\drivers\\etc\\hosts 添加:"
echo "    ${SERVER_IP}  www.test-web1.com"
echo "    ${SERVER_IP}  www.test-web2.com"
echo "  然后浏览器直接访问 http://www.test-web1.com"
