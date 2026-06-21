import Foundation

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var systemDisplayName: String {
        switch self {
        case .system:
            return "System"
        case .simplifiedChinese:
            return "Simplified Chinese"
        case .english:
            return "English"
        }
    }

    func displayName(using language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            switch self {
            case .system:
                return "跟随系统"
            case .simplifiedChinese:
                return "简体中文"
            case .english:
                return "英语"
            }
        default:
            return systemDisplayName
        }
    }
}

final class AppState {
    static let shared = AppState()

    private let defaults = UserDefaults.standard
    private let languageKey = "preferredLanguage"
    private let onboardingKey = "didShowOnboarding"
    private let menuBarIconKey = "showMenuBarIcon"

    var preferredLanguage: AppLanguage {
        get {
            let rawValue = defaults.string(forKey: languageKey) ?? AppLanguage.system.rawValue
            return AppLanguage(rawValue: rawValue) ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
        }
    }

    var effectiveLanguage: AppLanguage {
        switch preferredLanguage {
        case .system:
            let systemLanguage = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return systemLanguage.hasPrefix("zh") ? .simplifiedChinese : .english
        case .simplifiedChinese:
            return .simplifiedChinese
        case .english:
            return .english
        }
    }

    var didShowOnboarding: Bool {
        get { defaults.bool(forKey: onboardingKey) }
        set { defaults.set(newValue, forKey: onboardingKey) }
    }

    var showMenuBarIcon: Bool {
        get {
            if defaults.object(forKey: menuBarIconKey) == nil {
                return true
            }
            return defaults.bool(forKey: menuBarIconKey)
        }
        set {
            defaults.set(newValue, forKey: menuBarIconKey)
        }
    }
}

enum L10n {
    static func text(_ key: String) -> String {
        let language = AppState.shared.effectiveLanguage
        let table = strings[language] ?? strings[.english] ?? [:]
        return table[key] ?? key
    }

    static func languageDisplayName(_ language: AppLanguage) -> String {
        language.displayName(using: AppState.shared.effectiveLanguage)
    }

    private static let strings: [AppLanguage: [String: String]] = [
        .english: [
            "appName": "AutoSend",
            "settingsTitle": "AutoSend Settings",
            "settingsMenu": "Settings…",
            "enabled": "Enabled",
            "quit": "Quit",
            "generalSection": "Preferences",
            "language": "Language",
            "launchAtLogin": "Launch at Startup",
            "showMenuBarIcon": "Show Menu Bar Icon",
            "menuBarIcon": "Menu Bar Icon",
            "permissionsSection": "Permissions",
            "setupTitle": "INITIAL SETUP & REQUIRED ACCESS",
            "accessibility": "Accessibility",
            "accessibilityDetail": "Required to post the synthetic Return key.",
            "inputMonitoring": "Input Monitoring",
            "inputMonitoringDetail": "If AutoSend does not work, enable this and restart the app.",
            "inputMonitoringRestartHint": "If this stays gray after you turn it on, restart AutoSend.",
            "step1Title": "Step One",
            "step1Detail": "Required to simulate the Enter key for automated message delivery. Enable this if AutoSend is unresponsive, then restart the application.",
            "step1Action": "Open Accessibility Settings",
            "step2Title": "Step 2: Enable Input Monitoring",
            "step2Detail": "This permission is required. Open it, then follow the system prompt to restart AutoSend.",
            "step2Action": "Open Input Monitoring Settings",
            "restartPromptHighlight": "restart AutoSend",
            "restartTitle": "Step 3: Restart AutoSend",
            "restartDetail": "After Input Monitoring is enabled, restart once so the new permission takes effect.",
            "restartAction": "Restart App",
            "openAccessibilitySettings": "Open System Settings",
            "openInputMonitoringSettings": "Open Input Monitoring Settings",
            "recheckPermissions": "Re-verify",
            "goToSettings": "Settings",
            "grantAccess": "Grant Access",
            "reverify": "Re-verify",
            "aboutSection": "Information",
            "advancedSection": "Advanced Actions",
            "aboutVersion": "Version",
            "aboutProject": "GitHub Project",
            "aboutIssue": "Report Issue",
            "aboutCheckUpdates": "Check for Updates",
            "aboutUpdateDescription": "Stay up to date with the latest features and fixes.",
            "aboutCheckingUpdates": "Checking for Updates…",
            "aboutUpToDate": "You are up to date.",
            "aboutUpdateFailed": "Update check failed.",
            "aboutUpdateAvailable": "Version %@ is available.",
            "aboutOpenReleases": "Open Releases",
            "restartRequired": "Permissions changed. Restart AutoSend to apply them.",
            "restartNow": "Restart App",
            "monitoringFailedTitle": "AutoSend could not start keyboard monitoring",
            "monitoringFailedBody": "Input Monitoring is optional. If double-tap detection does not work, enable Input Monitoring for AutoSend, then restart the app.",
            "accessibilityGranted": "AUTHORIZED",
            "accessibilityMissing": "UNAUTHORIZED",
            "inputGranted": "AUTHORIZED",
            "inputMissing": "UNAUTHORIZED",
            "permissionsMissingTitle": "Permissions Still Missing",
            "permissionsMissingBody": "AutoSend needs Accessibility to watch Left Control and send Return. Input Monitoring is optional and shown here if you want to improve reliability.",
            "openAtLoginFailed": "Open at Login Failed",
            "openAtLoginEnabled": "Open at Login is enabled.",
            "openAtLoginDisabled": "Open at Login is disabled.",
            "statusEnabled": "On",
            "statusDisabled": "Off",
            "ok": "OK",
            "followSystem": "Follow System",
            "simplifiedChinese": "Chinese (Simplified)",
            "english": "English",
            "settingsIntroTitle": "AutoSend Settings",
            "settingsIntroBody": "Double-tap Control to simulate Enter.",
        ],
        .simplifiedChinese: [
            "appName": "AutoSend",
            "settingsTitle": "AutoSend 设置",
            "settingsMenu": "设置…",
            "enabled": "启用",
            "quit": "退出",
            "generalSection": "偏好设置",
            "language": "语言",
            "launchAtLogin": "开机自启",
            "showMenuBarIcon": "显示菜单栏图标",
            "menuBarIcon": "菜单栏图标",
            "permissionsSection": "权限",
            "setupTitle": "初始设置与必需访问",
            "accessibility": "辅助功能",
            "accessibilityDetail": "用于发送模拟的回车键。",
            "inputMonitoring": "输入监控",
            "inputMonitoringDetail": "如果 AutoSend 没反应，请在这里开启，然后重启应用。",
            "inputMonitoringRestartHint": "如果开启后还是灰色，请重启 AutoSend。",
            "step1Title": "第一步",
            "step1Detail": "这是 AutoSend 自动发送回车所必需的权限。若应用没有响应，请先开启它，然后重启应用。",
            "step1Action": "打开辅助功能设置",
            "step2Title": "第二步：开启输入监控",
            "step2Detail": "这是必需权限。请打开后，按系统提示重启 AutoSend。",
            "step2Action": "打开输入监控设置",
            "restartPromptHighlight": "按系统提示重启",
            "restartTitle": "第三步：重启 AutoSend",
            "restartDetail": "输入监控打开后，请重启一次，让新权限生效。",
            "restartAction": "重启应用",
            "openAccessibilitySettings": "打开系统设置",
            "openInputMonitoringSettings": "打开输入监控设置",
            "recheckPermissions": "重新验证",
            "goToSettings": "去设置",
            "grantAccess": "授权访问",
            "reverify": "重新验证",
            "aboutSection": "信息",
            "advancedSection": "高级操作",
            "aboutVersion": "版本",
            "aboutProject": "GitHub 项目",
            "aboutIssue": "反馈",
            "aboutCheckUpdates": "检查更新",
            "aboutUpdateDescription": "保持最新版本，获取功能改进和问题修复。",
            "aboutCheckingUpdates": "正在检查更新…",
            "aboutUpToDate": "当前已经是最新版本。",
            "aboutUpdateFailed": "更新检查失败。",
            "aboutUpdateAvailable": "发现新版本 %@。",
            "aboutOpenReleases": "打开 Releases",
            "restartRequired": "权限已变更，请重启 AutoSend 以生效。",
            "restartNow": "重启应用",
            "monitoringFailedTitle": "AutoSend 无法启动键盘监听",
            "monitoringFailedBody": "输入监控是可选项。如果双击没有反应，请为 AutoSend 打开输入监控，然后重启应用。",
            "accessibilityGranted": "已授权",
            "accessibilityMissing": "未授权",
            "inputGranted": "已授权",
            "inputMissing": "未授权",
            "permissionsMissingTitle": "权限仍未齐全",
            "permissionsMissingBody": "AutoSend 需要辅助功能权限才能监听左 Control 并发送回车。输入监控是可选项，想提升稳定性时可在这里开启。",
            "openAtLoginFailed": "开机自启设置失败",
            "openAtLoginEnabled": "已开启开机自启。",
            "openAtLoginDisabled": "已关闭开机自启。",
            "statusEnabled": "开",
            "statusDisabled": "关",
            "ok": "确定",
            "followSystem": "跟随系统",
            "simplifiedChinese": "简体中文",
            "english": "英语",
            "settingsIntroTitle": "AutoSend 设置",
            "settingsIntroBody": "连按两下 Control 即可模拟 Enter。",
        ]
    ]
}
