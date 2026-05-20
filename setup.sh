#!/bin/bash
# doubao-auto-send 安装/卸载脚本
# 用法: bash setup.sh install|uninstall

set -e

PLIST_NAME="com.jago.auto-send"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/auto_send.py"
LOG_DIR="$HOME/Library/Logs/auto-send"

install() {
    echo "安装 doubao-auto-send..."

    mkdir -p "$LOG_DIR"

    # 通过 Terminal.app 启动，继承终端的辅助功能权限
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>Terminal</string>
        <string>${SCRIPT_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

    launchctl load "$PLIST_PATH" 2>/dev/null || launchctl start "$PLIST_NAME"
    echo ""
    echo "✓ 已安装并启动"
    echo ""
    echo "确保 Terminal.app 已有辅助功能权限："
    echo "  系统设置 → 隐私与安全性 → 辅助功能 → 勾选 Terminal"
}

uninstall() {
    echo "卸载 doubao-auto-send..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "✓ 已卸载"
}

case "${1:-}" in
    install)   install ;;
    uninstall) uninstall ;;
    *)
        echo "用法: bash setup.sh install|uninstall"
        exit 1
        ;;
esac
