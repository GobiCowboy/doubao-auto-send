# doubao-auto-send

<p align="center">
  <b>中文</b> | <a href="README.md">English</a>
</p>

> 连按两下左 Control 键，自动发送回车。macOS 轻量工具。

## 为什么需要这个？

使用豆包输入法语音输入后，说完话手已经离开键盘，还要换手去按回车键。

这个工具让你**连按两下左 Control** 即可发送消息。单手操作，不用换手。

## 工作流程

```
Fn 触发豆包语音输入 → 说话 → 松开 → 连按两下左 Control → 自动回车发送
```

## 下载安装

### 方式一：直接下载（推荐）

1. 前往 [Releases](https://github.com/GobiCowboy/doubao-auto-send/releases) 下载 `AutoSend.app`
2. 拖入 `/Applications` 文件夹，或用发布包直接安装到 `/Applications`
3. 首次打开后在设置页里完成语言、开机自启和权限配置

### 方式二：从源码编译

需要 macOS 13.0+ 和 Xcode Command Line Tools：

```bash
cd Swift
make install
```

这个命令会生成适合本机测试的本地签名包。如果要正式分发，请使用下面的发布脚本。

### 方式三：Python 版

```bash
pip3 install pyobjc-framework-Quartz pyobjc-framework-ApplicationServices
python3 auto_send.py
```

## 权限设置

首次运行前，需在 **系统设置 → 隐私与安全性** 中授权：

1. **辅助功能**（Accessibility）→ 勾选 AutoSend
2. **输入监控**（Input Monitoring）→ 勾选 AutoSend
3. 返回应用后在设置页里完成配置，或者重新启动应用

说明：

- 这个应用用 `CGEventTap` 监听全局按键，所以通常需要输入监控。
- 它还会模拟回车键，所以需要辅助功能。

## 功能

- **双击检测**：连按两下左 Control（间隔 300ms 内）自动发送回车
- **菜单栏常驻**：状态栏只保留设置、启用/禁用、退出等最小动作
- **独立设置页**：语言、开机自启、权限都放在单独页面里
- **纯监听模式**：不拦截或修改任何键盘事件，只监听
- **触发反馈**：触发时菜单栏图标闪绿色

## 兼容性

| 项目 | 说明 |
|------|------|
| macOS 版本 | 13.0+（Swift 版）/ 12.0+（Python 版） |
| 输入法 | 不限，豆包、搜狗、系统自带均可 |
| 应用 | 不限，微信、浏览器、飞书、终端等均可使用 |
| 与其他快捷键冲突 | 左 Control 在 macOS 上极少单独使用，无冲突 |

## 技术实现

通过 macOS `CGEventTap` 监听 `flagsChanged` 事件，检测左 Control 键（keyCode 59）的按下-释放-按下序列。两次按下间隔小于 300ms 则判定为双击，通过 `CGEventPost` 模拟回车键（keyCode 36）。

## 发布

如果要给别人直接打开，请使用 Developer ID 签名 + notarization + stapling，而不是只用本地 ad-hoc 签名。发布脚本会完成签名、提交 Apple 公证、staple 票据、校验结果，并把最终包安装到 `/Applications`。示例：

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE=Apple-Notary \
./scripts/release_arm64.sh
```

## 项目结构

```
doubao-auto-send/
├── README.md
├── auto_send.py          # Python 版（已验证可用）
├── requirements.txt
├── setup.sh
└── Swift/
    ├── Package.swift
    ├── Info.plist
    ├── Makefile
    ├── Resources/        # 应用图标
    └── Sources/AutoSend/ # Swift 原生版本
```

## License

MIT
