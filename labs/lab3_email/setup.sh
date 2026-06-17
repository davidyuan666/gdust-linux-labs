#!/bin/bash
set -e

echo "=== 实验3：搭建邮件服务器 ==="

echo -n "请输入 QQ 邮箱地址 (如 123456@qq.com): "
read QQ_EMAIL
echo -n "请输入 QQ 邮箱 SMTP 授权码: "
read -s QQ_AUTH_CODE
echo ""

echo "[1/4] 安装 Postfix ..."
yum install -y postfix mailx cyrus-sasl-plain

echo "[2/4] 配置 Postfix main.cf ..."
cp /etc/postfix/main.cf /etc/postfix/main.cf.bak.$(date +%Y%m%d)
cat >> /etc/postfix/main.cf << EOF
relayhost = [smtp.qq.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
EOF

echo "[3/4] 配置认证文件 ..."
cat > /etc/postfix/sasl_passwd << EOF
[smtp.qq.com]:587 ${QQ_EMAIL}:${QQ_AUTH_CODE}
EOF
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

echo "[4/4] 启动服务 ..."
systemctl enable postfix
systemctl restart postfix

echo ""
echo "=== 实验3 安装完成 ==="
echo "测试发送邮件命令："
echo "  echo 'Test mail from Rocky Linux' | mail -s 'Test Subject' 收件人@qq.com"
