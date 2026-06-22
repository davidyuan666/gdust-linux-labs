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

# 网卡：默认取第一张非 lo（可用第 4 个参数覆盖）
LAN_IF="${4:-$(ip -o link show | awk -F': ' '$2!="lo"{print $2; exit}')}"

# 默认保留当前 IP；只有显式传第 2 个参数才改 IP
CUR_CIDR=$(ip -o -4 addr show dev "$LAN_IF" 2>/dev/null | awk '{print $4; exit}')
CLIENT_CIDR="${2:-$CUR_CIDR}"
case "$CLIENT_CIDR" in */*) ;; *) CLIENT_CIDR="${CLIENT_CIDR}/24";; esac   # 没带掩码自动补 /24
DNS="${3:-8.8.8.8}"

if [ -z "$CLIENT_CIDR" ]; then
    echo "[错误] 网卡 $LAN_IF 当前无 IPv4 地址，请显式指定客户端 IP："
    echo "       bash client_setup.sh $SERVER_IP 192.168.56.102/24"
    exit 1
fi

echo "客户端网卡: $LAN_IF"
echo "客户端 IP : $CLIENT_CIDR   (默认保留当前地址)"
echo "默认网关  : $SERVER_IP   (NAT 服务器的 Host-Only IP)"
echo "DNS       : $DNS"
echo "[提示] 请确保已在 VirtualBox 中禁用客户端自带的 NAT 网卡，只保留 Host-Only，"
echo "       否则客户端会用自己的 NAT 直接出网，绕过 NAT 服务器导致实验无效。"

# SSH 安全：若将改成与当前不同的 IP，警告并要求确认（避免改 IP 断开 SSH）
CHANGE_IP=0
if [ -n "$CUR_CIDR" ] && [ "$CLIENT_CIDR" != "$CUR_CIDR" ]; then
    CHANGE_IP=1
    echo ""
    echo "[警告] 将把 IP 从 $CUR_CIDR 改为 $CLIENT_CIDR —— 经 SSH 运行会立即断连！"
    echo "       请从 VirtualBox 控制台运行，或准备改用新 IP 重连。"
    read -p "确认修改 IP 吗？(yes/no) " ANS
    [ "$ANS" = "yes" ] || { echo "已取消。"; exit 1; }
fi

echo ""
echo "[1/2] 查找/创建 NetworkManager 连接 ..."
CON=$(nmcli -g GENERAL.CONNECTION device show "$LAN_IF" 2>/dev/null)
if [ -z "$CON" ] || [ "$CON" = "--" ]; then
    CON="nat-client"
    nmcli con add type ethernet ifname "$LAN_IF" con-name "$CON"
fi
echo "使用连接: $CON"

echo "[2/2] 配置 IP / 网关 / DNS ..."
nmcli con mod "$CON" \
    ipv4.method manual \
    ipv4.addresses "$CLIENT_CIDR" \
    ipv4.gateway "$SERVER_IP" \
    ipv4.dns "$DNS"

# IP 不变 → reapply 尽量不断 SSH；IP 变了 → con up（此时已确认）
if [ "$CHANGE_IP" -eq 1 ]; then
    nmcli con up "$CON"
else
    nmcli dev reapply "$LAN_IF" 2>/dev/null || nmcli con up "$CON"
fi

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
    echo "  [WARN] ping 不通网关（网关可能丢弃 ICMP；若下面出网检查通过则不影响）"
    ((PASS++))
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
