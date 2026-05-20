# doubao-auto-send

连按两下左 Control 键，自动发送回车。macOS 轻量工具，无依赖安装。

适用场景：豆包输入法语音输入后，快速发送消息（单手操作，不用换手去按回车）。

## 工作流程

```
Fn 触发豆包语音输入 → 说话 → 松开 → 连按两下左 Control → 自动回车发送
```

## 系统要求

- macOS 12.0+（Monterey 及以上）
- Python 3.8+
- 终端需要「辅助功能」和「输入监控」权限

## 安装

```bash
# 克隆项目
git clone <repo-url> doubao-auto-send
cd doubao-auto-send

# 安装依赖
pip3 install pyobjc-framework-Quartz pyobjc-framework-ApplicationServices
```

## 权限设置

首次运行前，需在 **系统设置 → 隐私与安全性** 中授权：

1. **辅助功能**（Accessibility）→ 勾选你的终端（iTerm2 / Terminal）
2. **输入监控**（Input Monitoring）→ 勾选你的终端

## 使用

```bash
# 前台运行（有日志输出，Ctrl+C 退出）
python3 auto_send.py

# 后台运行
nohup python3 auto_send.py > /tmp/auto_send.log 2>&1 &

# 暂停/恢复切换
kill -USR1 $(pgrep -f auto_send.py)

# 停止
kill $(pgrep -f auto_send.py)
```

## 开机自启

```bash
# 安装 LaunchAgent（开机自动启动）
bash setup.sh install

# 卸载
bash setup.sh uninstall
```

安装后重启 Mac 也会自动运行。日志位于 `~/Library/Logs/auto-send/`。

## 兼容性

| 项目 | 说明 |
|------|------|
| macOS 版本 | 12.0+，CGEventTap API 在各版本通用 |
| 输入法 | 不限，豆包、搜狗、系统自带均可 |
| 应用 | 不限，微信、浏览器、飞书、终端等均可使用 |
| 与其他快捷键冲突 | 左 Control 在 macOS 上极少单独使用，无冲突 |

## 原理

通过 macOS CGEventTap 监听 `FlagsChanged` 事件，检测左 Control 键的按下-释放-按下序列。两次按下间隔小于 300ms 则判定为双击，通过 `CGEventPost` 模拟回车键。

纯监听模式，不拦截或修改任何键盘事件。
