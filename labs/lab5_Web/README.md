# 实验5：搭建 Web 服务器

## 实验目的

使用 Apache (httpd) 搭建 Web 服务器，实现基于域名的虚拟主机，使一个 IP 地址承载多个网站。

## 实验要求

1. 安装 Apache 和 BIND
2. 配置 DNS 区域解析
3. 创建虚拟主机目录和默认页面
4. 配置基于域名的虚拟主机
5. 验证两个域名均能正确访问

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

- httpd 服务正常运行
- named 服务正常运行
- curl www.test-web1.com 返回 "this is web1"
- curl www.test-web2.com 返回 "this is web2"
