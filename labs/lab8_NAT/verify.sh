#!/bin/bash

echo "=== 实验8 验收：NAT 服务器 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] IP 转发状态 ..."
if [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = "1" ]; then
    echo "  [PASS] ip_forward = 1"
    ((PASS++))
else
    echo "  [FAIL] ip_forward 未启用"
    ((FAIL++))
fi

echo ""
echo "[检查] iptables 服务状态 ..."
if systemctl is-active iptables &>/dev/null; then
    echo "  [PASS] iptables 正在运行"
    ((PASS++))
else
    echo "  [FAIL] iptables 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] FORWARD 链规则 ..."
if iptables -L FORWARD -n 2>/dev/null | grep -q "ACCEPT"; then
    echo "  [PASS] FORWARD 规则存在"
    ((PASS++))
else
    echo "  [WARN] FORWARD 链无 ACCEPT 规则"
    ((PASS++))
fi

echo ""
echo "[检查] MASQUERADE 规则 ..."
if iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE"; then
    echo "  [PASS] MASQUERADE (SNAT) 规则存在"
    ((PASS++))
else
    echo "  [FAIL] MASQUERADE 规则不存在"
    ((FAIL++))
fi

echo ""
echo "[检查] firewalld 已禁用 ..."
if systemctl is-active firewalld &>/dev/null; then
    echo "  [WARN] firewalld 仍在运行（可能与 iptables 冲突）"
else
    echo "  [PASS] firewalld 已停止"
    ((PASS++))
fi

echo ""
echo "[检查] 规则已持久化 ..."
if [ -f /etc/sysconfig/iptables ]; then
    if [ -s /etc/sysconfig/iptables ]; then
        echo "  [PASS] /etc/sysconfig/iptables 已保存"
        ((PASS++))
    else
        echo "  [WARN] /etc/sysconfig/iptables 为空"
        ((PASS++))
    fi
else
    echo "  [FAIL] /etc/sysconfig/iptables 不存在"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
