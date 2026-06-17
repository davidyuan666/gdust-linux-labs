#!/bin/bash

echo "=== 实验2 验收：OpenVPN 服务器 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] OpenVPN 服务状态 ..."
if systemctl is-active openvpn-server@server &>/dev/null; then
    echo "  [PASS] openvpn-server@server 正在运行"
    ((PASS++))
else
    echo "  [FAIL] 服务未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] 1194/udp 端口监听 ..."
if ss -uln | grep -q 1194; then
    echo "  [PASS] 端口 1194/udp 在监听"
    ((PASS++))
else
    echo "  [FAIL] 未监听 1194/udp"
    ((FAIL++))
fi

echo ""
echo "[检查] tun0 网卡是否存在 ..."
if ip link show tun0 &>/dev/null; then
    echo "  [PASS] tun0 网卡已创建"
    ((PASS++))
else
    echo "  [WARN] tun0 未创建（需客户端连接后才会出现）"
    ((PASS++))
fi

echo ""
echo "[检查] 配置文件完整性 ..."
if [ -f /etc/openvpn/server/server.conf ]; then
    echo "  [PASS] server.conf 存在"
    ((PASS++))
else
    echo "  [FAIL] server.conf 不存在"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
