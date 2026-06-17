# 实验6：搭建 Samba 服务器

## 实验目的

使用 Samba 搭建跨平台文件共享服务器，实现多用户、多组、分权限的文件共享方案。

## 实验要求

1. 安装 Samba 组件
2. 创建 system、develop、productdesign、test、develop_test 组
3. 创建对应用户并设置 Samba 密码
4. 配置共享目录及权限
5. 客户端挂载验证

## 权限矩阵

| 目录 | 所有者 | develop | productdesign | test | 匿名 |
|------|--------|---------|---------------|------|------|
| /data/share | system | - | - | - | - |
| /data/share/develop | develop | 读写 | 不可访问 | 不可访问 | - |
| /data/share/productdesign | productdesign | 不可访问 | 读写 | 不可访问 | - |
| /data/share/test | test | 不可访问 | 不可访问 | 读写 | - |
| /data/share/library | system | 只读 | 只读 | 只读 | 只读 |
| /data/share/develop_test | - | 读写 | 不可访问 | 读写 | - |
| /data/share/temp | system | 读写 | 读写 | 读写 | 读写 |

## 操作步骤

### 1. 执行安装脚本

```bash
sudo bash setup.sh
```

### 2. 验证配置

```bash
sudo bash verify.sh
```

## 验收标准

- smb 服务正常运行
- testparm 配置语法检查通过
- 各用户目录权限正确
