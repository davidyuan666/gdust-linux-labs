#!/bin/bash

echo "=== 实验4 验收：DHCP 和 DNS 服务器 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] dnsmasq 服务状态 ..."
if systemctl is-active dnsmasq &>/dev/null; then
    echo "  [PASS] dnsmasq 正在运行"
    ((PASS++))
else
    echo "  [FAIL] dnsmasq 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] DHCP 配置段 ..."
if grep -q "^dhcp-range" /etc/dnsmasq.conf 2>/dev/null; then
    echo "  [PASS] DHCP 地址池已配置"
    ((PASS++))
else
    echo "  [FAIL] 未配置 DHCP 地址池"
    ((FAIL++))
fi

echo ""
echo "[检查] DNS 域名配置 ..."
if grep -q "^domain=tecmint.lan" /etc/dnsmasq.conf 2>/dev/null; then
    echo "  [PASS] DNS 域名已配置"
    ((PASS++))
else
    echo "  [FAIL] 未配置 DNS 域名"
    ((FAIL++))
fi

echo ""
echo "[检查] DNS 本地解析 ..."
SERVER_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[ -z "$SERVER_IP" ] && SERVER_IP="192.168.56.10"
if nslookup tecmint.lan ${SERVER_IP} &>/dev/null; then
    echo "  [PASS] tecmint.lan 可解析"
    ((PASS++))
else
    echo "  [FAIL] tecmint.lan 解析失败"
    ((FAIL++))
fi

echo ""
echo "[检查] 配置语法 ..."
if dnsmasq --test 2>/dev/null; then
    echo "  [PASS] 配置语法正确"
    ((PASS++))
else
    echo "  [FAIL] 配置语法错误"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
