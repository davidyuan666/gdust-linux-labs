#!/bin/bash
set -e

echo "=== 实验6：搭建 Samba 服务器 ==="

SERVER_IP=$(ip -o -4 addr show | grep '192\.168\.56\.' | awk '{print $4}' | cut -d/ -f1 | head -1)
[ -z "$SERVER_IP" ] && SERVER_IP="192.168.56.101"
echo "服务器 IP (Host-Only): $SERVER_IP"

echo "[1/7] 安装 Samba ..."
yum install -y samba samba-client samba-common cifs-utils

echo "[2/7] 创建目录结构 ..."
mkdir -p /data/share/{develop,productdesign,test,library,develop_test,temp}

echo "[3/7] 创建用户和组 ..."
groupadd -f system
groupadd -f develop
groupadd -f productdesign
groupadd -f test
groupadd -f develop_test

id develop       &>/dev/null || useradd -g develop       -G develop_test -d /data/share/develop        -s /sbin/nologin develop
id productdesign &>/dev/null || useradd -g productdesign -G develop_test -d /data/share/productdesign -s /sbin/nologin productdesign
id test          &>/dev/null || useradd -g test          -G develop_test -d /data/share/test            -s /sbin/nologin test
id system        &>/dev/null || useradd -g system        -G develop,productdesign,test,develop_test -d /data/share -s /sbin/nologin system

echo "[4/7] 设置目录权限 ..."
chmod 755  /data/share
chown system:system /data/share
chmod 2770 /data/share/develop /data/share/productdesign /data/share/test /data/share/develop_test
chmod 3777 /data/share/temp
chmod 755  /data/share/library
chown develop:system       /data/share/develop
chown productdesign:system /data/share/productdesign
chown test:system          /data/share/test
chown system:system        /data/share/library
chown system:system        /data/share/temp
setfacl -m g:develop:rwx /data/share/develop_test 2>/dev/null || true
setfacl -m g:test:rwx    /data/share/develop_test 2>/dev/null || true

echo "[5/7] 配置 Samba ..."
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak.$(date +%Y%m%d)
cat > /etc/samba/smb.conf << 'EOF'
[global]
    workgroup = SYSTEM
    server string = Linux Samba Server
    security = user
    map to guest = Bad User

[system]
    comment = System Admin Share
    path = /data/share/
    writeable = yes
    valid users = system
    browseable = yes

[library]
    path = /data/share/library
    writeable = no
    browseable = yes
    guest ok = yes

[temp]
    path = /data/share/temp
    writeable = yes
    browseable = yes
    guest ok = yes

[develop]
    path = /data/share/develop
    writeable = yes
    browseable = yes
    valid users = @develop,@system

[productdesign]
    path = /data/share/productdesign
    writeable = yes
    browseable = yes
    valid users = @productdesign,@system

[test]
    path = /data/share/test
    writeable = yes
    browseable = yes
    valid users = @test,@system

[develop_test]
    path = /data/share/develop_test
    writeable = yes
    browseable = yes
    valid users = @develop,@test,@system
EOF

echo "[6/7] 设置 Samba 用户密码 ..."
echo -e "123456\n123456" | smbpasswd -s -a system
echo -e "123456\n123456" | smbpasswd -s -a develop
echo -e "123456\n123456" | smbpasswd -s -a productdesign
echo -e "123456\n123456" | smbpasswd -s -a test

echo "[7/7] 配置防火墙并启动服务 ..."
firewall-cmd --permanent --add-service=samba 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true
systemctl enable smb
systemctl restart smb

echo ""
echo "=== 实验6 安装完成 ==="
echo "所有 Samba 用户密码默认为 123456"
echo ""
echo "从 Windows 宿主访问:"
echo "  文件资源管理器地址栏: \\\\${SERVER_IP}\\develop"
echo "  用户名: develop  密码: 123456"
echo "  命令行: net use Z: \\\\${SERVER_IP}\\develop /user:develop 123456"
