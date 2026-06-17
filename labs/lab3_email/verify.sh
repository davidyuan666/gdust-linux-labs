#!/bin/bash

echo "=== 实验3 验收：邮件服务器 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] Postfix 服务状态 ..."
if systemctl is-active postfix &>/dev/null; then
    echo "  [PASS] postfix 正在运行"
    ((PASS++))
else
    echo "  [FAIL] postfix 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] Postfix main.cf 中继配置 ..."
if grep -q "relayhost.*smtp.qq.com" /etc/postfix/main.cf 2>/dev/null; then
    echo "  [PASS] QQ邮箱中继已配置"
    ((PASS++))
else
    echo "  [FAIL] 未配置 QQ 邮箱中继"
    ((FAIL++))
fi

echo ""
echo "[检查] SASL 认证文件 ..."
if [ -f /etc/postfix/sasl_passwd ]; then
    echo "  [PASS] sasl_passwd 存在"
    ((PASS++))
else
    echo "  [FAIL] sasl_passwd 不存在"
    ((FAIL++))
fi
if [ -f /etc/postfix/sasl_passwd.db ]; then
    echo "  [PASS] sasl_passwd.db 已生成"
    ((PASS++))
else
    echo "  [FAIL] sasl_passwd.db 不存在（请运行 postmap）"
    ((FAIL++))
fi

echo ""
echo "[检查] Postfix 配置语法 ..."
if postfix check 2>/dev/null; then
    echo "  [PASS] 配置语法正确"
    ((PASS++))
else
    echo "  [FAIL] 配置语法错误"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
