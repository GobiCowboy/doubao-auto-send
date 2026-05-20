#!/usr/bin/env python3
"""
连按两下左 Control → 模拟回车（发送）
纯监听模式，不拦截任何按键事件

用法：
  python3 auto_send.py              # 启动
  kill -USR1 <pid>                  # 暂停/恢复
  Ctrl+C                            # 退出
"""

import os
import sys
import time
import signal
import logging
import threading
import subprocess

import Quartz

# ── 配置 ──────────────────────────────────────────────────────────
DOUBLE_TAP_INTERVAL = 0.3     # 双击间隔（秒）
CTRL_FLAG = 0x40000           # kCGEventFlagMaskControl

# ── 日志 ──────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("ctrl-enter")

# ── 全局状态 ──────────────────────────────────────────────────────
paused = False
last_ctrl_time = 0.0
ctrl_was_down = False
cooldown = False              # 触发后冷却，防止 Enter 事件再次触发


def press_enter():
    source = Quartz.CGEventSourceCreate(Quartz.kCGEventSourceStateHIDSystemState)
    # 确保事件干净，无任何修饰键
    down = Quartz.CGEventCreateKeyboardEvent(source, 36, True)
    Quartz.CGEventSetFlags(down, 0)
    up = Quartz.CGEventCreateKeyboardEvent(source, 36, False)
    Quartz.CGEventSetFlags(up, 0)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, down)
    time.sleep(0.02)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, up)
    log.debug("Enter 已发送")


def notify(text):
    subprocess.run(
        ["osascript", "-e",
         f'display notification "{text}" with title "Auto Send"'],
        capture_output=True,
    )


def toggle_pause(signum, frame):
    global paused
    paused = not paused
    state = "已暂停" if paused else "已恢复"
    log.info(f"SIGUSR1 → {state}")


def event_callback(proxy, event_type, event, refcon):
    global last_ctrl_time, ctrl_was_down, cooldown

    if paused:
        return event

    flags = Quartz.CGEventGetFlags(event)
    ctrl_down = bool(flags & CTRL_FLAG)

    # 检测 Ctrl 按下瞬间（状态从 非Ctrl → Ctrl）
    if ctrl_down and not ctrl_was_down:
        ctrl_was_down = True

        if cooldown:
            cooldown = False
            return event

        now = time.time()
        gap = now - last_ctrl_time

        if gap < DOUBLE_TAP_INTERVAL:
            # 双击！
            log.info(f"双击 Ctrl (间隔 {gap:.0f}ms) → 自动回车")
            # 延迟 200ms 发送 Enter，等 Ctrl 释放完成
            threading.Timer(0.2, press_enter).start()
            notify("双击 Ctrl → 已发送")
            last_ctrl_time = 0
            cooldown = True
        else:
            # 第一次按下，记录时间
            last_ctrl_time = now
            log.debug(f"Ctrl 按下，等待第二次...")

    # Ctrl 释放
    if not ctrl_down and ctrl_was_down:
        ctrl_was_down = False
        if cooldown:
            cooldown = False

    return event


def main():
    signal.signal(signal.SIGUSR1, toggle_pause)

    mask = Quartz.CGEventMaskBit(Quartz.kCGEventFlagsChanged)
    tap = Quartz.CGEventTapCreate(
        Quartz.kCGSessionEventTap,
        Quartz.kCGHeadInsertEventTap,
        Quartz.kCGEventTapOptionListenOnly,  # 纯监听，不拦截
        mask,
        event_callback,
        None,
    )

    if not tap:
        log.error("CGEventTap 创建失败！请授予「辅助功能」和「输入监控」权限")
        sys.exit(1)

    source = Quartz.CFMachPortCreateRunLoopSource(None, tap, 0)
    Quartz.CFRunLoopAddSource(
        Quartz.CFRunLoopGetCurrent(), source, Quartz.kCFRunLoopDefaultMode
    )
    Quartz.CGEventTapEnable(tap, True)

    log.info(f"已启动 (PID={os.getpid()})")
    log.info(f"连按两下左 Control → 自动回车 (间隔 {DOUBLE_TAP_INTERVAL}s)")
    log.info("kill -USR1 <pid> 暂停/恢复，Ctrl+C 退出")

    try:
        Quartz.CFRunLoopRun()
    except KeyboardInterrupt:
        log.info("已退出")
        notify("Auto Send 已停止")


if __name__ == "__main__":
    main()
