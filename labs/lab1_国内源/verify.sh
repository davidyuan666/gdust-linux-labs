#!/bin/bash

echo "=== 实验1 验收：YUM 国内源 ==="
PASS=0
FAIL=0

echo ""
echo "[检查] 阿里云 repo 配置文件是否存在 ..."
if [ -f /etc/yum.repos.d/rocky-aliyun.repo ]; then
    echo "  [PASS] rocky-aliyun.repo 存在"
    ((PASS++))
else
    echo "  [FAIL] rocky-aliyun.repo 不存在"
    ((FAIL++))
fi

echo ""
echo "[检查] 仓库列表中包含阿里云 ..."
if yum repolist 2>/dev/null | grep -qi "aliyun"; then
    echo "  [PASS] 阿里云仓库已启用"
    ((PASS++))
else
    echo "  [FAIL] 未找到阿里云仓库"
    ((FAIL++))
fi

echo ""
echo "[检查] dnf makecache 是否正常 ..."
if yum makecache --quiet 2>/dev/null; then
    echo "  [PASS] 缓存重建成功"
    ((PASS++))
else
    echo "  [FAIL] 缓存重建失败"
    ((FAIL++))
fi

echo ""
echo "[检查] 尝试搜索一个软件包 ..."
if yum search vim 2>/dev/null | grep -q vim; then
    echo "  [PASS] 软件包搜索正常"
    ((PASS++))
else
    echo "  [FAIL] 软件包搜索异常"
    ((FAIL++))
fi

echo ""
echo "=== 结果：$PASS 通过, $FAIL 失败 ==="
if [ "$FAIL" -gt 0 ]; then
    echo "验收不通过，请检查配置"
    exit 1
else
    echo "验收通过"
    exit 0
fi
