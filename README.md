# 车间计件 · iPadOS 原生离线版

纯 SwiftUI 原生应用，不使用 WebView，不发起任何网络请求。数据保存在应用沙盒内的 SQLite 数据库。

## 当前功能

- 固定横屏，仅支持 iPad / arm64
- iPadOS 15.0 及以上
- 全部账单：正式账单与本地草稿按日期倒序合并展示
- 计件录入：客户/员工下拉、型号自由输入、历史型号本地联想、数量正整数、色数 1–5
- 草稿：按日期绑定、自动保存、后台保存、放弃草稿
- 浏览正式账单但未修改即返回时，不生成草稿
- 可修改账单日期补记过去流水
- 客户、员工档案本地增删改查
- 原始流水、员工统计、客户统计
- 客户统计支持按日、按月、完整年度，并可按 1–5 色筛选和分类汇总
- CSV 导出：UTF-8 BOM，列中不包含提交时间
- 本机 SQLite 数据库备份导出
- 合计只统计 `计酬工作量 = 数量 × 色数`

## 服务器连接预留

- 当前版本不要求密码或账号，启动后直接进入离线账本。
- 当前版本不会发起任何服务器请求。
- `WorkshopLedger/Services/RemoteLedgerService.swift` 已预留服务器配置、上传协议和远端账单 DTO。
- 默认注入 `DisabledRemoteLedgerService`，因此网络能力处于关闭状态。
- 后续验证服务器时，新增 HTTPS 客户端并替换注入实现即可；客户、员工、账单、报表和 SQLite 数据结构无需重写。
- 账号、密码、登录状态和服务器地址设置界面均未在当前版本实现。

## 目录

```text
WorkshopLedger/                  SwiftUI 源码、SQLite、Info.plist、图标
project.yml                      XcodeGen 工程定义
.github/workflows/build-ipa.yml  GitHub Actions 无签名 IPA 构建
tools/generate_icons.py          可选的图标重新生成脚本
```

## GitHub Actions 生成 IPA

1. 在 GitHub 新建一个仓库。
2. 将本目录全部文件上传到仓库，默认分支使用 `main`。
3. 打开仓库的 **Actions** 页面，选择 **Build unsigned arm64 IPA**。
4. 点击 **Run workflow**。
5. 构建完成后，在该次运行底部下载 `WorkshopLedger-iOS-arm64-unsigned` Artifact。
6. 解压 Artifact，得到：
   - `WorkshopLedger-iOS-arm64-unsigned.ipa`
   - `SHA256SUMS.txt`
7. 将 IPA 传到 iPad，使用 TrollStore 打开并安装。

### 说明

- GitHub Actions 只负责在 macOS 运行器上编译，不会替用户上传文件到 iPad。
- 产物是无签名 arm64 IPA，专供 TrollStore 安装，不能用于 App Store。
- iPadOS 15 首次打开若提示开发者信任或 TrollStore 需要刷新签名，按 TrollStore 的常规流程处理。
- 删除 App 会同时删除其沙盒内的 SQLite 数据库，请先通过“备份数据库”导出备份文件。

## 本机验证

当前 Windows 环境没有 Xcode 和 iOS SDK，因此无法在本机完成 `xcodebuild`。最终编译状态以 GitHub Actions 的 macOS 运行器为准。