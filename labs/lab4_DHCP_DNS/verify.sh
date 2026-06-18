#!/bin/bash

echo "=== 实验4 验收：DHCP 和 DNS 服务器 ==="
PASS=0
FAIL=0

SERVER_IP="10.100.0.1"

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
if nslookup tecmint.lan ${SERVER_IP} &>/dev/null; then
    echo "  [PASS] tecmint.lan 可解析"
    ((PASS++))
else
    echo "  [FAIL] tecmint.lan 解析失败"
    ((FAIL++))
fi

echo ""
echo "[检查] 内部网络网卡配置 ..."
NIC3=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -F "${SERVER_IP}" | cut -d: -f2 | head -1)
if [ -z "$NIC3" ]; then
    NIC3=$(ip -o -4 addr show | grep "${SERVER_IP}" | awk '{print $2}' | head -1)
fi
if [ -n "$NIC3" ] && ip link show "$NIC3" &>/dev/null; then
    echo "  [PASS] 内部网络网卡 ${NIC3} 已配置 (IP: ${SERVER_IP})"
    ((PASS++))
else
    echo "  [FAIL] 未找到绑定 ${SERVER_IP} 的网卡，请确认 NIC3 已添加（内部网络模式）"
    ((FAIL++))
fi

echo ""
echo "[检查] DHCP 租约 ..."
if [ -f /var/lib/misc/dnsmasq.leases ] && [ -s /var/lib/misc/dnsmasq.leases ]; then
    echo "  [PASS] DHCP 租约文件存在，已有客户端获取 IP"
    cat /var/lib/misc/dnsmasq.leases 2>/dev/null | while read line; do
        echo "        租约: $line"
    done
    ((PASS++))
else
    echo "  [WARN] DHCP 租约文件为空或不存在，请确认 NIC3 已通过 DHCP 获取 IP"
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
