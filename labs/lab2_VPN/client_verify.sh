#!/bin/bash

echo "=== 实验2 验收：VPN 客户端 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] openvpn-client 服务状态 ..."
if systemctl is-active openvpn-client@client &>/dev/null; then
    echo "  [PASS] openvpn-client@client 正在运行"
    ((PASS++))
else
    echo "  [FAIL] openvpn-client@client 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] tun0 网卡 ..."
if ip link show tun0 &>/dev/null; then
    VPNADDR=$(ip -4 addr show tun0 2>/dev/null | grep -oP 'inet \K[\d.]+')
    echo "  [PASS] tun0 已创建 (VPN IP: ${VPNADDR:-?})"
    ((PASS++))
else
    echo "  [FAIL] tun0 未创建（隧道未建立）"
    ((FAIL++))
fi

echo ""
echo "[检查] 隧道连通性（ping 服务端 10.8.0.1）..."
sleep 2
if ping -c 2 -W 3 10.8.0.1 &>/dev/null; then
    echo "  [PASS] 可 ping 通服务端 VPN IP (10.8.0.1)"
    ((PASS++))
else
    echo "  [FAIL] 无法 ping 通 10.8.0.1（隧道未连通）"
    ((FAIL++))
fi

echo ""
echo "[检查] 推送路由 ..."
if ip route show 2>/dev/null | grep -q "192.168.56.0.*tun0"; then
    echo "  [PASS] 路由 192.168.56.0/24 via tun0 已添加"
    ((PASS++))
else
    echo "  [FAIL] 未检测到 192.168.56.0/24 推送路由"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
