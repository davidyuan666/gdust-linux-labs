#!/bin/bash

echo "=== 实验6 验收：Samba 服务器 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] smb 服务状态 ..."
if systemctl is-active smb &>/dev/null; then
    echo "  [PASS] smb 正在运行"
    ((PASS++))
else
    echo "  [FAIL] smb 未运行"
    ((FAIL++))
fi

echo ""
echo "[检查] testparm 配置语法 ..."
if testparm -s 2>/dev/null | grep -q "Loaded services"; then
    echo "  [PASS] 配置语法正确"
    ((PASS++))
else
    echo "  [FAIL] 配置语法错误"
    ((FAIL++))
fi

echo ""
echo "[检查] Samba 用户 ..."
for user in system develop productdesign test; do
    if pdbedit -L 2>/dev/null | grep -q "^${user}:"; then
        echo "  [PASS] Samba 用户 $user 存在"
        ((PASS++))
    else
        echo "  [FAIL] Samba 用户 $user 不存在"
        ((FAIL++))
    fi
done

echo ""
echo "[检查] Samba 共享定义 ..."
for share in system library temp develop_test develop productdesign test; do
    if testparm -s 2>/dev/null | grep -q "^\[${share}\]"; then
        echo "  [PASS] 共享 [$share] 已定义"
        ((PASS++))
    else
        echo "  [FAIL] 共享 [$share] 未定义"
        ((FAIL++))
    fi
done

echo ""
echo "[检查] 目录存在性 ..."
for d in develop productdesign test library develop_test temp; do
    if [ -d "/data/share/$d" ]; then
        echo "  [PASS] /data/share/$d 存在"
        ((PASS++))
    else
        echo "  [FAIL] /data/share/$d 不存在"
        ((FAIL++))
    fi
done

echo ""
echo "[检查] develop 用户访问权限 ..."
echo "123456" | smbclient //localhost/develop -U develop -c "ls" 2>/dev/null | grep -q "blocks available" && {
    echo "  [PASS] develop 用户可访问 develop 共享"
    ((PASS++))
} || {
    echo "  [FAIL] develop 用户无法访问 develop 共享"
    ((FAIL++))
}
echo "123456" | smbclient //localhost/productdesign -U develop -c "ls" 2>/dev/null | grep -q "NT_STATUS" && {
    echo "  [PASS] develop 用户被正确拒绝访问 productdesign 共享"
    ((PASS++))
} || {
    echo "  [WARN] develop 用户访问 productdesign 未按预期拒绝"
    ((PASS++))
}

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
