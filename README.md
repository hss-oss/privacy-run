# PrivacyRun

PrivacyRun 是一款 macOS App 级隐私环境启动器。它为指定应用构建独立的进程环境，并在不修改 macOS 全局设置的前提下启动目标 App。

## 功能

- 按 App 配置时区、语言和地区格式。
- 使用独立 `TMPDIR`，不修改系统目录。
- 自动运行 Probe，验证目标进程可继承的环境结果。
- 只读检测系统默认字体。
- 查询公网 IP 国家或地区，并判断其与配置时区是否一致。
- 在本机保存最近一次运行报告。
- 直接启动 `.app` Bundle 中的 executable。
- 使用 Environment Allowlist，避免向目标 App 透传 Token、Cookie 和调试变量。

## 能力边界

PrivacyRun 不修改系统时间、系统时区或系统语言，不使用 Root、VM、代码注入、重签名或 Native Hook。

环境设置只对由 PrivacyRun 创建并且遵循相应 Environment 或 Apple Argument Domain 的进程生效。独立 Helper、XPC Service、Login Item、Native API、账号地区和服务端历史不在保证范围内。

系统默认字体仅供检测，无法像 `TZ` 一样进行可靠的进程级覆盖。公网 IP 查询只用于显示出口国家或地区，不会隐藏或更改 IP。

## 系统要求

- macOS 14 或更高版本
- Swift 6
- Xcode Command Line Tools

## 构建

```bash
git clone git@github.com:hss-oss/privacy-run.git
cd privacy-run
scripts/build-app.sh
```

构建产物位于：

```text
dist/PrivacyRun.app
```

启动：

```bash
open dist/PrivacyRun.app
```

`build-app.sh` 会构建主程序和 Probe、生成 `AppIcon.icns`、组装标准 macOS App Bundle，并执行本地 Ad Hoc 签名。

## 测试

```bash
swift test
```

测试覆盖 Environment Allowlist、时区与 IP 国家映射、Apple 启动参数和报告结果判断。

## 目录结构

```text
Sources/PrivacyRunApp/       SwiftUI App
Sources/PrivacyRunCore/      环境、启动、Probe 与报告逻辑
Sources/PrivacyRunProbe/     独立环境检测程序
Tests/PrivacyRunCoreTests/   单元测试
Support/                     App Bundle 元数据
scripts/                     图标与 App 构建脚本
assets/                      图标和文档图片
```

## 隐私

- 配置和运行报告默认只保存在本机。
- 不包含 Analytics、远程日志或 Crash Upload。
- IP 属地查询由用户点击“启动 App”触发，查询服务能够看到该次请求的公网 IP。
- 运行报告只保存 IP 国家或地区代码，不保存完整公网 IP。

## License

本项目基于 [MIT License](LICENSE) 开源。
