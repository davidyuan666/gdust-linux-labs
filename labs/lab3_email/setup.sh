#!/bin/bash
set -e

echo "=== 实验3：搭建 SMTP 邮件发送客户端 ==="

echo -n "请输入发件邮箱地址 (如 yourname@qq.com 或 yourname@163.com): "
read SENDER_EMAIL

case "$SENDER_EMAIL" in
    *@qq.com)
        SMTP_HOST="smtp.qq.com"
        SMTP_PORT="587"
        TLS_EXTRA=""
        echo "检测到 QQ 邮箱，SMTP: ${SMTP_HOST}:${SMTP_PORT}" ;;
    *@163.com)
        SMTP_HOST="smtp.163.com"
        SMTP_PORT="465"
        TLS_EXTRA="smtp_tls_wrappermode = yes"
        echo "检测到 163 邮箱，SMTP: ${SMTP_HOST}:${SMTP_PORT}" ;;
    *)
        echo "错误: 目前仅支持 QQ 邮箱(@qq.com) 和 163 邮箱(@163.com)"
        exit 1 ;;
esac

echo -n "请输入该邮箱的 SMTP 授权码: "
read AUTH_CODE
echo ""

echo "[1/4] 安装 Postfix ..."
yum install -y postfix s-nail cyrus-sasl-plain

echo "[2/4] 配置 Postfix main.cf ..."
cp /etc/postfix/main.cf /etc/postfix/main.cf.bak.$(date +%Y%m%d)
cat >> /etc/postfix/main.cf << EOF
relayhost = [${SMTP_HOST}]:${SMTP_PORT}
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
${TLS_EXTRA}
EOF

echo "[3/4] 配置认证文件 ..."
cat > /etc/postfix/sasl_passwd << EOF
[${SMTP_HOST}]:${SMTP_PORT} ${SENDER_EMAIL}:${AUTH_CODE}
EOF
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

echo "[4/4] 启动服务 ..."
systemctl enable postfix
systemctl restart postfix

echo ""
echo "=== 实验3 安装完成 ==="
echo "测试发送邮件命令："
echo "  echo 'Test mail from Rocky Linux' | mail -s 'Test Subject' 收件人@example.com"
