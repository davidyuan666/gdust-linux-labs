# 实验3：搭建邮件服务器

## 实验目的

使用 Postfix 搭建邮件服务器，配置通过 QQ 邮箱 SMTP 中继发送邮件。

## 实验要求

1. 安装 Postfix 邮件服务
2. 配置 QQ 邮箱 SMTP 中继
3. 配置 SASL 认证
4. 发送测试邮件

## 前置条件

- 一个 QQ 邮箱账号，已在 QQ 邮箱设置中生成授权码
  - 路径：QQ邮箱 → 设置 → 账户 → POP3/SMTP服务 → 生成授权码

## 操作步骤

### 1. 准备授权码

登录 QQ 邮箱获取 SMTP 授权码（16位字符）

### 2. 执行安装脚本

```bash
sudo bash setup.sh
```

脚本会提示输入 QQ 邮箱地址和授权码。

### 3. 验证配置

```bash
sudo bash verify.sh
```

## 验收标准

- postfix 服务正常运行
- /etc/postfix/sasl_passwd 已配置
- 发送测试邮件成功，接收方能收到邮件
