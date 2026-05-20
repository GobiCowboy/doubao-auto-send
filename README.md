# doubao-auto-send

轻量级 macOS 输入框监听工具。监听所有应用输入框，当文本末尾出现「发送」时自动按回车。

适用场景：豆包输入法语音输入，说完"发送"自动发出消息。

## 原理

- macOS Accessibility API 每 200ms 读取当前焦点输入框文本
- 检测到末尾为「发送」→ Quartz 模拟回车键
- 触发后进入冷却，文本变化后才允许再次触发（防重复）

## 依赖

macOS 自带 Python 模块，无需额外安装：

- `ApplicationServices`（Accessibility API）
- `Quartz`（按键模拟）

## 权限

需在 **系统设置 → 隐私与安全性** 中授予运行脚本的终端以下权限：

- **辅助功能**（Accessibility）
- **输入监控**（Input Monitoring）

## 使用

```bash
# 启动
python3 auto_send.py

# 后台运行
nohup python3 auto_send.py > /dev/null 2>&1 &

# 暂停/恢复切换
kill -USR1 $(pgrep -f auto_send.py)

# 停止
kill $(pgrep -f auto_send.py)
```

## 安装为开机自启（LaunchAgent）

```bash
bash setup.sh install
```

卸载：

```bash
bash setup.sh uninstall
```

## 日志

脚本运行时会输出检测日志，方便调试：

```
15:40:19 [INFO] Auto Send 已启动 (PID=59735)
15:40:22 [INFO] 检测到末尾「发送」→ 自动回车
```
