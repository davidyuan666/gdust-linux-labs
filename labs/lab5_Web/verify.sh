#!/bin/bash

echo "=== 实验5 验收：Web 服务器 ==="
PASS=0
FAIL=0

SERVER_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"

echo ""
echo "[检查] httpd 服务状态 ..."
if systemctl is-active httpd &>/dev/null; then
    echo "  [PASS] httpd 正在运行"
    ((PASS++))
else
    echo "  [FAIL] httpd 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] named 服务状态 ..."
if systemctl is-active named &>/dev/null; then
    echo "  [PASS] named 正在运行"
    ((PASS++))
else
    echo "  [FAIL] named 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] test-web1.com 虚拟主机 ..."
WEB1=$(curl -s -H "Host: www.test-web1.com" "http://${SERVER_IP}/" 2>/dev/null)
if echo "$WEB1" | grep -q "this is web1"; then
    echo "  [PASS] test-web1.com 返回正确: $WEB1"
    ((PASS++))
else
    echo "  [FAIL] test-web1.com 未返回预期内容"
    ((FAIL++))
fi

echo ""
echo "[检查] test-web2.com 虚拟主机 ..."
WEB2=$(curl -s -H "Host: www.test-web2.com" "http://${SERVER_IP}/" 2>/dev/null)
if echo "$WEB2" | grep -q "this is web2"; then
    echo "  [PASS] test-web2.com 返回正确: $WEB2"
    ((PASS++))
else
    echo "  [FAIL] test-web2.com 未返回预期内容"
    ((FAIL++))
fi

echo ""
echo "[检查] 虚拟主机配置文件 ..."
if [ -f /etc/httpd/conf.d/vhosts.conf ]; then
    echo "  [PASS] vhosts.conf 存在"
    ((PASS++))
else
    echo "  [FAIL] vhosts.conf 不存在"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
