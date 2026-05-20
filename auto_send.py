#!/usr/bin/env python3
"""
轻量级 macOS 输入框监听工具
监听所有应用输入框文本，当末尾出现"发送"时自动按回车
适用于豆包输入法语音输入场景：说"发送"即可自动发出消息

用法：
  python3 auto_send.py              # 启动监听
  python3 auto_send.py --disable    # 直接退出（用于关闭）
  kill -USR1 <pid>                  # 暂停/恢复切换
"""

import os
import sys
import time
import signal
import logging
import argparse
import subprocess

import ApplicationServices
import Quartz

# ── 配置 ──────────────────────────────────────────────────────────
TRIGGER_TEXT = "发送"
POLL_INTERVAL = 0.2          # 轮询间隔（秒）
COOLDOWN_TEXT = "__TRIGGERED__"  # 冷却标记，非真实文本

# ── 日志 ──────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("auto-send")

# ── 全局状态 ──────────────────────────────────────────────────────
paused = False
last_triggered_text = None


# ── 辅助功能 API ──────────────────────────────────────────────────

def get_focused_element():
    """获取当前前台应用的焦点 UI 元素"""
    app = ApplicationServices.NSWorkspace.sharedWorkspace().frontmostApplication()
    if app is None:
        return None
    pid = app.processIdentifier()
    app_ref = ApplicationServices.AXUIElementCreateApplication(pid)
    err, focused = ApplicationServices.AXUIElementCopyAttributeValue(
        app_ref, "AXFocusedUIElement", None
    )
    if err == 0 and focused is not None:
        return focused
    return app_ref


def get_text(element):
    """读取 UI 元素的文本内容"""
    if element is None:
        return None
    err, value = ApplicationServices.AXUIElementCopyAttributeValue(
        element, "AXValue", None
    )
    if err == 0 and isinstance(value, str):
        return value
    return None


# ── 模拟按键 ──────────────────────────────────────────────────────

def press_enter():
    """模拟按下回车键"""
    source = Quartz.CGEventSourceCreate(Quartz.kCGEventSourceStateHIDSystemState)
    key_code = 36  # Return 键

    down = Quartz.CGEventCreateKeyboardEvent(source, key_code, True)
    up = Quartz.CGEventCreateKeyboardEvent(source, key_code, False)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, down)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, up)


# ── 通知 ──────────────────────────────────────────────────────────

def notify(text):
    """发送 macOS 通知中心通知"""
    subprocess.run(
        ["osascript", "-e",
         f'display notification "{text}" with title "Auto Send"'],
        capture_output=True,
    )


# ── 信号处理 ──────────────────────────────────────────────────────

def toggle_pause(signum, frame):
    global paused
    paused = not paused
    state = "已暂停" if paused else "已恢复"
    log.info(f"收到 SIGUSR1 → {state}")
    notify(f"Auto Send {state}")


# ── 主逻辑 ────────────────────────────────────────────────────────

def check_once():
    """单次检测：读取输入框文本，判断是否触发回车"""
    global last_triggered_text

    text = get_text(get_focused_element())
    if text is None:
        return

    # 冷却中：文本必须变化才允许再次触发
    if last_triggered_text is not None:
        if text == last_triggered_text:
            return
        last_triggered_text = None

    # 检测末尾
    if text.rstrip().endswith(TRIGGER_TEXT):
        log.info(f"检测到末尾「{TRIGGER_TEXT}」→ 自动回车")
        press_enter()
        notify("检测到「发送」，已自动回车")
        last_triggered_text = text


def main():
    global paused

    signal.signal(signal.SIGUSR1, toggle_pause)

    log.info(f"Auto Send 已启动 (PID={os.getpid()})")
    log.info(f"触发词：「{TRIGGER_TEXT}」  轮询间隔：{POLL_INTERVAL}s")
    log.info("kill -USR1 <pid> 可暂停/恢复，Ctrl+C 退出")
    log.info("请确保终端已授予「辅助功能」和「输入监控」权限")
    notify("Auto Send 已启动，监听「发送」自动回车")

    try:
        while True:
            if not paused:
                try:
                    check_once()
                except Exception as e:
                    log.debug(f"检测异常: {e}")
            time.sleep(POLL_INTERVAL)
    except KeyboardInterrupt:
        log.info("已退出")
        notify("Auto Send 已停止")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="监听输入框，末尾为「发送」时自动回车")
    parser.add_argument("--disable", action="store_true", help="直接退出")
    args = parser.parse_args()
    if args.disable:
        sys.exit(0)
    main()
