#!/bin/bash
set -e

echo "=== 实验8：【NAT 客户端端】配置 ==="

# 取 NAT 服务器(网关)的 Host-Only IP：命令行参数 > 默认 > 交互兜底
SERVER_IP="${1:-}"
DEFAULT_SERVER_IP="192.168.56.101"
if [ -z "$SERVER_IP" ]; then
    read -p "请输入 NAT 服务器的 Host-Only IP [默认 $DEFAULT_SERVER_IP]: " SERVER_IP
    SERVER_IP="${SERVER_IP:-$DEFAULT_SERVER_IP}"
fi

# 可选参数：客户端 IP / DNS / 网卡（均带默认值）
CLIENT_IP="${2:-192.168.56.50}"
DNS="${3:-8.8.8.8}"
LAN_IF="${4:-$(ip -o link show | awk -F': ' '$2!="lo"{print $2; exit}')}"

echo "客户端网卡: $LAN_IF"
echo "客户端 IP : $CLIENT_IP/24"
echo "默认网关  : $SERVER_IP   (NAT 服务器的 Host-Only IP)"
echo "DNS       : $DNS"
echo "[提示] 请确保已在 VirtualBox 中禁用客户端自带的 NAT 网卡，只保留 Host-Only，"
echo "       否则客户端会用自己的 NAT 直接出网，绕过 NAT 服务器导致实验无效。"

echo ""
echo "[1/2] 查找/创建 NetworkManager 连接 ..."
CON=$(nmcli -g GENERAL.CONNECTION device show "$LAN_IF" 2>/dev/null)
if [ -z "$CON" ] || [ "$CON" = "--" ]; then
    CON="nat-client"
    nmcli con add type ethernet ifname "$LAN_IF" con-name "$CON"
fi
echo "使用连接: $CON"

echo "[2/2] 配置静态 IP / 网关 / DNS ..."
nmcli con mod "$CON" \
    ipv4.method manual \
    ipv4.addresses "${CLIENT_IP}/24" \
    ipv4.gateway "$SERVER_IP" \
    ipv4.dns "$DNS"
nmcli con up "$CON"

# ===== 内置功能验证（格式与 verify.sh 一致，不因失败中断）=====
set +e
echo ""
echo "=== 实验8 客户端验证 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] 默认路由指向网关 ..."
if ip route show default | grep -q "via $SERVER_IP"; then
    echo "  [PASS] 默认路由 via $SERVER_IP"
    ((PASS++))
else
    echo "  [FAIL] 默认路由未指向 $SERVER_IP"
    ((FAIL++))
fi

echo ""
echo "[检查] 连通 NAT 网关 ..."
if ping -c2 -W2 "$SERVER_IP" &>/dev/null; then
    echo "  [PASS] 可达网关 $SERVER_IP"
    ((PASS++))
else
    echo "  [FAIL] 无法 ping 通网关（检查 Host-Only 网络 / 服务器 IP）"
    ((FAIL++))
fi

echo ""
echo "[检查] 经 NAT 访问外网 IP ..."
if ping -c2 -W3 8.8.8.8 &>/dev/null; then
    echo "  [PASS] 可达 8.8.8.8（服务器转发 + MASQUERADE 生效）"
    ((PASS++))
else
    echo "  [FAIL] 无法访问外网（检查服务器的 ip_forward / MASQUERADE）"
    ((FAIL++))
fi

echo ""
echo "[检查] 域名解析 + HTTP 访问 ..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://www.baidu.com 2>/dev/null)
case "$HTTP_CODE" in
    200|301|302)
        echo "  [PASS] 经 NAT 访问 www.baidu.com (HTTP $HTTP_CODE)"
        ((PASS++))
        ;;
    *)
        echo "  [WARN] HTTP 访问返回 $HTTP_CODE（IP 层已通，可能 DNS 未生效）"
        ((PASS++))
        ;;
esac

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
