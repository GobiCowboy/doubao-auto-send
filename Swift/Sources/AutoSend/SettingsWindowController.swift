import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {
    private enum SetupStage {
        case accessibility
        case inputMonitoring
    }

    private let permissionManager: PermissionManager
    private let onLanguageChanged: () -> Void
    private let onToggleLaunchAtLogin: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onOpenInputMonitoringSettings: () -> Void
    private let onRecheck: () -> Void
    private let onRestartApp: () -> Void
    private var currentRestartRequired = false

    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let guideSectionLabel = NSTextField(labelWithString: "")
    private let guideCardView = NSView()
    private let guideTitleLabel = NSTextField(labelWithString: "")
    private let guideDetailLabel = NSTextField(labelWithString: "")
    private let guideActionButton = NSButton(title: "", target: nil, action: nil)
    private let guideRestartButton = NSButton(title: "", target: nil, action: nil)

    private let generalSectionLabel = NSTextField(labelWithString: "")
    private let languageLabel = NSTextField(labelWithString: "")
    private let languagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    private let permissionsSectionLabel = NSTextField(labelWithString: "")
    private let accessibilityTitleLabel = NSTextField(labelWithString: "")
    private let accessibilityDetailLabel = NSTextField(labelWithString: "")
    private let accessibilityStateLabel = NSTextField(labelWithString: "")
    private let inputMonitoringTitleLabel = NSTextField(labelWithString: "")
    private let inputMonitoringDetailLabel = NSTextField(labelWithString: "")
    private let inputMonitoringStateLabel = NSTextField(labelWithString: "")
    private let inputMonitoringHintLabel = NSTextField(labelWithString: "")
    private let openAccessibilityButton = NSButton(title: "", target: nil, action: nil)
    private let openInputMonitoringButton = NSButton(title: "", target: nil, action: nil)
    private let recheckButton = NSButton(title: "", target: nil, action: nil)

    init(
        permissionManager: PermissionManager,
        onLanguageChanged: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onOpenInputMonitoringSettings: @escaping () -> Void,
        onRecheck: @escaping () -> Void,
        onRestartApp: @escaping () -> Void
    ) {
        self.permissionManager = permissionManager
        self.onLanguageChanged = onLanguageChanged
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onOpenInputMonitoringSettings = onOpenInputMonitoringSettings
        self.onRecheck = onRecheck
        self.onRestartApp = onRestartApp

        let contentViewController = NSViewController()
        super.init(window: NSWindow(contentViewController: contentViewController))

        configureWindow()
        contentViewController.view = makeContentView()
        refreshLocalizedContent()
        refreshLaunchAtLoginState()
        refreshWorkflowState(restartRequired: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshLocalizedContent() {
        window?.title = L10n.text("settingsTitle")

        titleLabel.stringValue = L10n.text("settingsIntroTitle")
        subtitleLabel.stringValue = L10n.text("settingsIntroBody")
        guideSectionLabel.stringValue = L10n.text("setupTitle")
        generalSectionLabel.stringValue = L10n.text("generalSection")
        languageLabel.stringValue = L10n.text("language")
        launchAtLoginCheckbox.title = L10n.text("launchAtLogin")
        permissionsSectionLabel.stringValue = L10n.text("permissionsSection")
        accessibilityTitleLabel.stringValue = L10n.text("accessibility")
        accessibilityDetailLabel.stringValue = L10n.text("accessibilityDetail")
        inputMonitoringTitleLabel.stringValue = L10n.text("inputMonitoring")
        inputMonitoringDetailLabel.stringValue = L10n.text("inputMonitoringDetail")
        inputMonitoringHintLabel.stringValue = L10n.text("inputMonitoringRestartHint")
        openAccessibilityButton.title = L10n.text("openAccessibilitySettings")
        openInputMonitoringButton.title = L10n.text("openInputMonitoringSettings")
        recheckButton.title = L10n.text("recheckPermissions")

        let selectedLanguage = AppState.shared.preferredLanguage
        languagePopup.removeAllItems()
        for language in AppLanguage.allCases {
            let item = NSMenuItem(
                title: language.displayName(using: AppState.shared.effectiveLanguage),
                action: nil,
                keyEquivalent: ""
            )
            item.representedObject = language.rawValue
            languagePopup.menu?.addItem(item)
        }
        selectLanguage(selectedLanguage)
        refreshWorkflowState(restartRequired: currentRestartRequired)
    }

    func refreshLaunchAtLoginState() {
        launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    func refreshWorkflowState(restartRequired: Bool) {
        currentRestartRequired = restartRequired
        let accessibilityGranted = permissionManager.isAccessibilityGranted()
        let inputMonitoringGranted = permissionManager.isInputMonitoringGranted()
        let stage = currentStage(
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            restartRequired: restartRequired
        )

        accessibilityStateLabel.stringValue = permissionStateText(
            granted: accessibilityGranted,
            grantedText: L10n.text("accessibilityGranted"),
            missingText: L10n.text("accessibilityMissing")
        )
        accessibilityStateLabel.textColor = accessibilityGranted ? .systemGreen : .systemRed

        inputMonitoringStateLabel.stringValue = permissionStateText(
            granted: inputMonitoringGranted,
            grantedText: L10n.text("inputGranted"),
            missingText: L10n.text("inputMissing")
        )
        inputMonitoringStateLabel.textColor = inputMonitoringGranted ? .systemGreen : .systemRed
        inputMonitoringHintLabel.isHidden = inputMonitoringGranted

        updateGuide(for: stage)
        updateSectionVisibility(accessibilityGranted: accessibilityGranted, inputMonitoringGranted: inputMonitoringGranted)
    }

    private func currentStage(accessibilityGranted: Bool, inputMonitoringGranted: Bool, restartRequired: Bool) -> SetupStage? {
        if !accessibilityGranted {
            return .accessibility
        }
        if !inputMonitoringGranted {
            return .inputMonitoring
        }
        if restartRequired {
            return .inputMonitoring
        }
        return nil
    }

    private func updateGuide(for stage: SetupStage?) {
        guard let stage else {
            guideSectionLabel.isHidden = true
            guideCardView.isHidden = true
            return
        }

        guideSectionLabel.isHidden = false
        guideCardView.isHidden = false
        guideTitleLabel.textColor = .labelColor

        switch stage {
        case .accessibility:
            guideTitleLabel.stringValue = L10n.text("step1Title")
            guideDetailLabel.attributedStringValue = attributedGuideDetail(
                text: L10n.text("step1Detail"),
                highlight: nil
            )
            guideActionButton.title = L10n.text("step1Action")
            guideActionButton.target = self
            guideActionButton.action = #selector(openAccessibility)
            guideActionButton.isHidden = false
            guideRestartButton.isHidden = true
        case .inputMonitoring:
            guideTitleLabel.stringValue = L10n.text("step2Title")
            guideDetailLabel.attributedStringValue = attributedGuideDetail(
                text: L10n.text("step2Detail"),
                highlight: L10n.text("restartPromptHighlight")
            )
            guideActionButton.title = L10n.text("step2Action")
            guideActionButton.target = self
            guideActionButton.action = #selector(openInputMonitoring)
            guideActionButton.isHidden = false
            guideRestartButton.title = L10n.text("restartAction")
            guideRestartButton.target = self
            guideRestartButton.action = #selector(restartApp)
            guideRestartButton.isHidden = false
        }
    }

    private func updateSectionVisibility(accessibilityGranted: Bool, inputMonitoringGranted: Bool) {
        openAccessibilityButton.isHidden = accessibilityGranted
        openInputMonitoringButton.isHidden = !accessibilityGranted || inputMonitoringGranted
        inputMonitoringHintLabel.isHidden = !accessibilityGranted || inputMonitoringGranted
        recheckButton.isHidden = false
    }

    private func configureWindow() {
        guard let window else { return }
        window.title = L10n.text("settingsTitle")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setContentSize(NSSize(width: 560, height: 460))
        window.minSize = NSSize(width: 560, height: 460)
        window.isMovableByWindowBackground = true
    }

    private func makeContentView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 460))

        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.maximumNumberOfLines = 2

        guideCardView.wantsLayer = true
        guideCardView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        guideCardView.layer?.cornerRadius = 12
        guideCardView.layer?.borderWidth = 1
        guideCardView.layer?.borderColor = NSColor.separatorColor.cgColor
        guideCardView.translatesAutoresizingMaskIntoConstraints = false

        guideTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        guideDetailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        guideDetailLabel.textColor = .secondaryLabelColor
        guideDetailLabel.maximumNumberOfLines = 0

        guideActionButton.target = self
        guideActionButton.action = #selector(openAccessibility)
        guideActionButton.bezelStyle = .rounded
        guideRestartButton.target = self
        guideRestartButton.action = #selector(restartApp)
        guideRestartButton.bezelStyle = .rounded

        let guideButtonRow = NSStackView(views: [guideActionButton, guideRestartButton])
        guideButtonRow.orientation = .horizontal
        guideButtonRow.alignment = .leading
        guideButtonRow.spacing = 10

        guideSectionLabel.isHidden = true
        guideCardView.isHidden = true

        let guideStack = NSStackView(views: [guideTitleLabel, guideDetailLabel, guideButtonRow])
        guideStack.orientation = .vertical
        guideStack.alignment = .leading
        guideStack.spacing = 12
        guideStack.translatesAutoresizingMaskIntoConstraints = false
        guideCardView.addSubview(guideStack)
        NSLayoutConstraint.activate([
            guideStack.leadingAnchor.constraint(equalTo: guideCardView.leadingAnchor, constant: 18),
            guideStack.trailingAnchor.constraint(equalTo: guideCardView.trailingAnchor, constant: -18),
            guideStack.topAnchor.constraint(equalTo: guideCardView.topAnchor, constant: 16),
            guideStack.bottomAnchor.constraint(equalTo: guideCardView.bottomAnchor, constant: -16),
        ])

        [guideSectionLabel, generalSectionLabel, permissionsSectionLabel].forEach {
            $0.font = .systemFont(ofSize: 12, weight: .semibold)
            $0.textColor = .secondaryLabelColor
        }

        [languageLabel, accessibilityTitleLabel, inputMonitoringTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .medium)
        }

        [accessibilityDetailLabel, inputMonitoringDetailLabel, inputMonitoringHintLabel].forEach {
            $0.font = .systemFont(ofSize: 12, weight: .regular)
            $0.textColor = .secondaryLabelColor
            $0.maximumNumberOfLines = 0
        }

        inputMonitoringHintLabel.textColor = .systemRed

        [accessibilityStateLabel, inputMonitoringStateLabel].forEach {
            $0.font = .systemFont(ofSize: 12, weight: .medium)
        }

        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)

        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(toggleLaunchAtLogin)

        openAccessibilityButton.target = self
        openAccessibilityButton.action = #selector(openAccessibility)
        openInputMonitoringButton.target = self
        openInputMonitoringButton.action = #selector(openInputMonitoring)
        recheckButton.target = self
        recheckButton.action = #selector(recheckPermissions)

        let languageRow = labeledRow(label: languageLabel, control: languagePopup)
        let launchRow = NSStackView(views: [launchAtLoginCheckbox])
        launchRow.orientation = .horizontal
        launchRow.alignment = .leading

        let generalStack = NSStackView(views: [languageRow, launchRow])
        generalStack.orientation = .vertical
        generalStack.alignment = .leading
        generalStack.spacing = 10

        let accessibilityRow = statusRow(title: accessibilityTitleLabel, state: accessibilityStateLabel)
        let inputMonitoringRow = statusRow(title: inputMonitoringTitleLabel, state: inputMonitoringStateLabel)

        let permissionsStack = NSStackView(views: [
            accessibilityRow,
            accessibilityDetailLabel,
            openAccessibilityButton,
            inputMonitoringRow,
            inputMonitoringDetailLabel,
            inputMonitoringHintLabel,
            openInputMonitoringButton,
            recheckButton,
        ])
        permissionsStack.orientation = .vertical
        permissionsStack.alignment = .leading
        permissionsStack.spacing = 8

        let rootStack = NSStackView(views: [
            titleLabel,
            subtitleLabel,
            guideSectionLabel,
            guideCardView,
            generalSectionLabel,
            generalStack,
            permissionsSectionLabel,
            permissionsStack,
        ])
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 14
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -24),
        ])

        return view
    }

    private func labeledRow(label: NSTextField, control: NSControl) -> NSStackView {
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .equalSpacing
        row.spacing = 12
        return row
    }

    private func statusRow(title: NSTextField, state: NSTextField) -> NSStackView {
        let row = NSStackView(views: [title, state])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .equalSpacing
        row.spacing = 12
        return row
    }

    private func permissionStateText(granted: Bool, grantedText: String, missingText: String) -> String {
        granted ? grantedText : missingText
    }

    private func attributedGuideDetail(text: String, highlight: String?) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2

        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: paragraphStyle,
            ]
        )

        if let highlight, !highlight.isEmpty {
            let nsText = text as NSString
            let range = nsText.range(of: highlight)
            if range.location != NSNotFound {
                attributed.addAttributes([
                    .foregroundColor: NSColor.systemRed,
                    .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                ], range: range)
            }
        }

        return attributed
    }

    private func selectLanguage(_ language: AppLanguage) {
        guard let items = languagePopup.menu?.items else { return }
        for index in 0..<items.count {
            let item = items[index]
            if item.representedObject as? String == language.rawValue {
                languagePopup.selectItem(at: index)
                return
            }
        }
        languagePopup.selectItem(at: 0)
    }

    @objc private func languageChanged() {
        guard let item = languagePopup.selectedItem,
              let language = AppLanguage(rawValue: item.representedObject as? String ?? AppLanguage.system.rawValue) else {
            return
        }
        AppState.shared.preferredLanguage = language
        onLanguageChanged()
    }

    @objc private func toggleLaunchAtLogin() {
        onToggleLaunchAtLogin()
        refreshLaunchAtLoginState()
    }

    @objc private func openAccessibility() {
        onOpenAccessibilitySettings()
    }

    @objc private func openInputMonitoring() {
        onOpenInputMonitoringSettings()
    }

    @objc private func recheckPermissions() {
        onRecheck()
    }

    @objc private func restartApp() {
        onRestartApp()
    }
}
