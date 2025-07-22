<!--
 * @Author: Vincent Young
 * @Date: 2022-07-01 15:29:23
 * @LastEditors: lbg43
 * @LastEditTime: 2022-07-30 19:28:49
 * @FilePath: /MTProxy-/README.md
 * @Telegram: https://t.me/missuo
 * 
 * Copyright © 2022 by Vincent, All Rights Reserved. 
-->
# MTProxy
用于[Telegram](https://telegram.org)的高度专业的（前"无废话"的）MTPROTO代理。

## 简介
**如果您以前使用过MTProxy，那么您使用的一定是Version 1。目前，互联网上的脚本基本上都是Version 1。而我的脚本使用了新的Version 2。**

### Version 1和Version 2的区别
- 配置文件不兼容
- Version 2完全移除了TAG
- Version 2使用FakeTLS加密

### 更新日志
#### 2025年7月14日
- 支持多实例部署，可在同一VPS上运行多个代理
- 实例管理系统，可单独管理每个实例
- 每个实例有独立的配置、端口和密钥

#### 2022年7月30日
- 支持修改监听端口
- 支持修改密钥
- 支持更新到最新版本的MTProxy

#### 2022年7月1日
- 添加订阅配置
- 添加订阅链接

#### 更新
- 优化MTProxy配置，支持通过name字段尝试自定义Telegram客户端中的代理显示名称
- 链接格式包含必要的服务器信息以确保正常连接（Telegram协议要求）
- 注意：代理在Telegram客户端中的显示方式可能因客户端版本和设置而异

## 支持平台
- X86_64
- ARM_64

## 安装方法
**此脚本默认使用[9seconds/mtg](https://github.com/9seconds/mtg)的最新发布版本**
~~~shell
bash <(curl -Ls https://raw.githubusercontent.com/lbg43/MTProxy-/main/mtproxy.sh)
~~~

## 多实例使用指南
### 安装新实例
1. 运行脚本，选择选项 `1`
2. 输入实例名称(如: proxy1, proxy2)
3. 输入域名和端口
4. 系统会自动生成连接信息

### 管理实例
- 列出所有实例: 选项 `3`
- 启动实例: 选项 `4`
- 停止实例: 选项 `5`
- 重启实例: 选项 `6`
- 删除实例: 选项 `7`

### 修改实例配置
- 修改端口: 选项 `8`
- 修改密钥: 选项 `9`

### 更新MTProxy
- 选项 `10` 将更新所有实例

## 使用的开源项目
[9seconds/mtg](https://github.com/9seconds/mtg)

## 作者

**MTProxy** © [Vincent Young](https://github.com/missuo)，由[lbg43](https://github.com/lbg43)分支维护，基于[MIT](./LICENSE)许可证发布。<br> 
