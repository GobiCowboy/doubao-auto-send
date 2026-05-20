#!/bin/bash
# doubao-auto-send 安装/卸载脚本
# 用法: bash setup.sh install|uninstall

set -e

PLIST_NAME="com.jago.auto-send"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_PATH="$(which python3)"
SCRIPT_PATH="${SCRIPT_DIR}/auto_send.py"
LOG_DIR="$HOME/Library/Logs/auto-send"

install() {
    echo "安装 doubao-auto-send..."

    # 创建日志目录
    mkdir -p "$LOG_DIR"

    # 生成 plist
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${PYTHON_PATH}</string>
        <string>${SCRIPT_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/stderr.log</string>
</dict>
</plist>
EOF

    # 加载
    launchctl load "$PLIST_PATH"
    echo "已安装并启动"
    echo "日志: ${LOG_DIR}/"
    echo ""
    echo "请确保终端已授予「辅助功能」和「输入监控」权限"
    echo "  系统设置 → 隐私与安全性 → 辅助功能"
    echo "  系统设置 → 隐私与安全性 → 输入监控"
}

uninstall() {
    echo "卸载 doubao-auto-send..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "已卸载"
}

case "${1:-}" in
    install)   install ;;
    uninstall) uninstall ;;
    *)
        echo "用法: bash setup.sh install|uninstall"
        exit 1
        ;;
esac
