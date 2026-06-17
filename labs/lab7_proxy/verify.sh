#!/bin/bash

echo "=== 实验7 验收：代理服务器 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] squid 服务状态 ..."
if systemctl is-active squid &>/dev/null; then
    echo "  [PASS] squid 正在运行"
    ((PASS++))
else
    echo "  [FAIL] squid 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] 代理端口监听 ..."
if ss -tln | grep -q 8080; then
    echo "  [PASS] 端口 8080 在监听"
    ((PASS++))
else
    echo "  [FAIL] 端口 8080 未监听"
    ((FAIL++))
fi

echo ""
echo "[检查] 配置文件存在 ..."
if [ -f /etc/squid/squid.conf ]; then
    if grep -q "http_port 8080" /etc/squid/squid.conf; then
        echo "  [PASS] 代理端口已配置为 8080"
        ((PASS++))
    else
        echo "  [FAIL] 未找到 http_port 8080 配置"
        ((FAIL++))
    fi
else
    echo "  [FAIL] squid.conf 不存在"
    ((FAIL++))
fi

echo ""
echo "[检查] 代理访问测试 ..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -x http://localhost:8080 http://www.baidu.com 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [PASS] 通过代理可访问外网 (HTTP $HTTP_CODE)"
    ((PASS++))
else
    echo "  [FAIL] 通过代理访问外网失败 (HTTP $HTTP_CODE)"
    ((FAIL++))
fi

echo ""
echo "[检查] 直接访问（不走代理）对比 ..."
DIRECT_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://www.baidu.com 2>/dev/null)
echo "  [INFO] 直接访问 HTTP $DIRECT_CODE (对比参考)"

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
