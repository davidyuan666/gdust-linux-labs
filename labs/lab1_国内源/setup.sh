#!/bin/bash
set -e

echo "=== 实验1：YUM 配置国内源 ==="

echo "[1/5] 修复原有 repo 中的 \$contentdir 变量 ..."
if grep -q '\$contentdir' /etc/yum.repos.d/rocky*.repo 2>/dev/null; then
    sed -i 's|\$contentdir|rocky|g' /etc/yum.repos.d/rocky*.repo
    echo "  \$contentdir 已替换为 rocky"
else
    echo "  无需修复，跳过"
fi

BACKUP_DIR="/etc/yum.repos.d/backup-$(date +%Y%m%d)"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "[2/5] 备份原有 repo 文件到 $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"
    cp /etc/yum.repos.d/*.repo "$BACKUP_DIR/" 2>/dev/null || true
    echo "  备份完成"
else
    echo "[2/5] 备份已存在，跳过"
fi

echo "[3/5] 写入阿里云镜像源配置 ..."
cat > /etc/yum.repos.d/rocky-aliyun.repo << 'EOF'
[baseos-aliyun]
name=Rocky Linux $releasever - BaseOS (Aliyun)
baseurl=https://mirrors.aliyun.com/rockylinux/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[appstream-aliyun]
name=Rocky Linux $releasever - AppStream (Aliyun)
baseurl=https://mirrors.aliyun.com/rockylinux/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[extras-aliyun]
name=Rocky Linux $releasever - Extras (Aliyun)
baseurl=https://mirrors.aliyun.com/rockylinux/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
EOF

echo "[4/5] 清理缓存并重建 ..."
yum clean all
yum makecache

echo "[5/5] 配置完成"
echo ""
echo "=== 实验1 安装完成 ==="
