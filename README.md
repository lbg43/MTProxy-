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
用于[Telegram](https://telegram.org)的高度专业的MTPROTO代理，支持隐藏服务器信息。

## 简介
**此脚本使用MTG的1.x版本，支持隐藏服务器IP和端口信息。当用户连接到您的代理时，Telegram客户端只会显示"MTPROTO"，而不会显示服务器详细信息。**

### 主要特性
- 使用MTG 1.x版本，支持adtag功能
- 在Telegram客户端中隐藏服务器IP和端口
- 多实例部署支持
- 简单易用的管理界面

### 更新日志
#### 2023年更新
- 使用MTG 1.x版本替代2.x版本
- 添加隐藏服务器信息功能（在Telegram客户端中仅显示"MTPROTO"）
- 更新配置文件格式，使用环境变量配置代替toml配置

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

## 支持平台
- X86_64
- ARM_64

## 安装方法
~~~shell
bash <(curl -Ls https://raw.githubusercontent.com/lbg43/MTProxy-/main/mtproxy.sh)
~~~

## 多实例使用指南
### 安装新实例
1. 运行脚本，选择选项 `1`
2. 输入实例名称(如: proxy1, proxy2)
3. 输入域名和端口
4. 系统会自动生成连接信息
5. 用户连接后，在Telegram客户端中只会显示"MTPROTO"

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
