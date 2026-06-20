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
    private let onQuitApp: () -> Void
    private var currentRestartRequired = false

    private let headerIconView = NSImageView()
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
    private let generalCardView = NSView()
    private let permissionsCardView = NSView()

    private let aboutSectionLabel = NSTextField(labelWithString: "")
    private let aboutVersionTitleLabel = NSTextField(labelWithString: "")
    private let aboutVersionValueLabel = NSTextField(labelWithString: "")
    private let aboutStatusLabel = NSTextField(labelWithString: "")
    private let openProjectButton = NSButton(title: "", target: nil, action: nil)
    private let openIssueButton = NSButton(title: "", target: nil, action: nil)
    private let checkUpdatesButton = NSButton(title: "", target: nil, action: nil)
    private let aboutCardView = NSView()
    private let advancedSectionLabel = NSTextField(labelWithString: "")
    private let quitButton = NSButton(title: "", target: nil, action: nil)
    private let advancedCardView = NSView()

    init(
        permissionManager: PermissionManager,
        onLanguageChanged: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onOpenInputMonitoringSettings: @escaping () -> Void,
        onRecheck: @escaping () -> Void,
        onRestartApp: @escaping () -> Void,
        onQuitApp: @escaping () -> Void
    ) {
        self.permissionManager = permissionManager
        self.onLanguageChanged = onLanguageChanged
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onOpenInputMonitoringSettings = onOpenInputMonitoringSettings
        self.onRecheck = onRecheck
        self.onRestartApp = onRestartApp
        self.onQuitApp = onQuitApp

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
        aboutSectionLabel.stringValue = L10n.text("aboutSection")
        advancedSectionLabel.stringValue = L10n.text("advancedSection")
        accessibilityTitleLabel.stringValue = L10n.text("accessibility")
        accessibilityDetailLabel.stringValue = L10n.text("accessibilityDetail")
        inputMonitoringTitleLabel.stringValue = L10n.text("inputMonitoring")
        inputMonitoringDetailLabel.stringValue = L10n.text("inputMonitoringDetail")
        inputMonitoringHintLabel.stringValue = L10n.text("inputMonitoringRestartHint")
        openAccessibilityButton.title = L10n.text("openAccessibilitySettings")
        openInputMonitoringButton.title = L10n.text("openInputMonitoringSettings")
        recheckButton.title = L10n.text("recheckPermissions")
        aboutVersionTitleLabel.stringValue = L10n.text("aboutVersion")
        aboutVersionValueLabel.stringValue = currentVersionString()
        aboutStatusLabel.stringValue = ""
        openProjectButton.title = L10n.text("aboutProject")
        openIssueButton.title = L10n.text("aboutIssue")
        checkUpdatesButton.title = L10n.text("aboutCheckUpdates")
        quitButton.title = L10n.text("quit")

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
        window.setContentSize(NSSize(width: 620, height: 680))
        window.minSize = NSSize(width: 620, height: 640)
        window.isMovableByWindowBackground = true
    }

    private func makeContentView() -> NSView {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 620, height: 680))
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 1100))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.maximumNumberOfLines = 2

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
        configureCardContainer(guideCardView, content: guideStack)

        headerIconView.image = AppIconProvider.appIcon()
        headerIconView.imageScaling = .scaleProportionallyDown
        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerIconView.widthAnchor.constraint(equalToConstant: 44),
            headerIconView.heightAnchor.constraint(equalToConstant: 44),
        ])

        [guideSectionLabel, generalSectionLabel, permissionsSectionLabel, aboutSectionLabel, advancedSectionLabel].forEach {
            $0.font = .systemFont(ofSize: 12, weight: .semibold)
            $0.textColor = .secondaryLabelColor
        }

        advancedSectionLabel.isHidden = false

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
        openProjectButton.target = self
        openProjectButton.action = #selector(openProject)
        openIssueButton.target = self
        openIssueButton.action = #selector(openIssue)
        checkUpdatesButton.target = self
        checkUpdatesButton.action = #selector(checkForUpdates)
        quitButton.target = self
        quitButton.action = #selector(quitApp)

        [openProjectButton, openIssueButton, checkUpdatesButton, quitButton].forEach {
            $0.bezelStyle = .inline
            $0.isBordered = false
            $0.imagePosition = .imageLeading
            $0.contentTintColor = .labelColor
            $0.alignment = .left
        }
        openProjectButton.image = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
        openIssueButton.image = NSImage(systemSymbolName: "exclamationmark.bubble", accessibilityDescription: nil)
        checkUpdatesButton.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        quitButton.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)

        let languageRow = labeledRow(label: languageLabel, control: languagePopup)
        let launchRow = NSStackView(views: [launchAtLoginCheckbox])
        launchRow.orientation = .horizontal
        launchRow.alignment = .leading

        let generalStack = NSStackView(views: [languageRow, launchRow])
        generalStack.orientation = .vertical
        generalStack.alignment = .leading
        generalStack.spacing = 10
        configureCardContainer(generalCardView, content: generalStack)

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
        configureCardContainer(permissionsCardView, content: permissionsStack)

        let aboutVersionRow = statusRow(title: aboutVersionTitleLabel, state: aboutVersionValueLabel)
        aboutVersionValueLabel.textColor = .secondaryLabelColor
        aboutStatusLabel.font = .systemFont(ofSize: 11, weight: .regular)
        aboutStatusLabel.textColor = .secondaryLabelColor
        aboutStatusLabel.maximumNumberOfLines = 0

        let aboutStack = NSStackView(views: [
            aboutVersionRow,
            openProjectButton,
            openIssueButton,
            checkUpdatesButton,
            aboutStatusLabel,
        ])
        aboutStack.orientation = .vertical
        aboutStack.alignment = .leading
        aboutStack.spacing = 8
        configureCardContainer(aboutCardView, content: aboutStack)

        let quitStack = NSStackView(views: [quitButton])
        quitStack.orientation = .vertical
        quitStack.alignment = .leading
        configureCardContainer(advancedCardView, content: quitStack)

        let titleStack = NSStackView(views: [titleLabel, subtitleLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let headerStack = NSStackView(views: [headerIconView, titleStack])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 12

        let rootStack = NSStackView(views: [
            headerStack,
            guideSectionLabel,
            guideCardView,
            generalSectionLabel,
            generalCardView,
            permissionsSectionLabel,
            permissionsCardView,
            aboutSectionLabel,
            aboutCardView,
            advancedSectionLabel,
            advancedCardView,
        ])
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 18
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.setHuggingPriority(.defaultLow, for: .horizontal)

        contentView.addSubview(rootStack)
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])

        return scrollView
    }

    private func labeledRow(label: NSTextField, control: NSControl) -> NSStackView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [label, spacer, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 12
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        control.setContentHuggingPriority(.required, for: .horizontal)
        control.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
    }

    private func statusRow(title: NSTextField, state: NSTextField) -> NSStackView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [title, spacer, state])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 12
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        state.setContentHuggingPriority(.required, for: .horizontal)
        state.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
    }

    private func configureCardContainer(_ container: NSView, content: NSView) {
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.cornerRadius = 12
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor.separatorColor.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let paddedContent = NSView()
        paddedContent.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(paddedContent)
        paddedContent.addSubview(content)

        NSLayoutConstraint.activate([
            paddedContent.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            paddedContent.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            paddedContent.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            paddedContent.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            content.leadingAnchor.constraint(equalTo: paddedContent.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: paddedContent.trailingAnchor),
            content.topAnchor.constraint(equalTo: paddedContent.topAnchor),
            content.bottomAnchor.constraint(equalTo: paddedContent.bottomAnchor),
        ])
    }

    private func permissionStateText(granted: Bool, grantedText: String, missingText: String) -> String {
        granted ? grantedText : missingText
    }

    private func currentVersionString() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
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

    @objc private func quitApp() {
        onQuitApp()
    }

    @objc private func openProject() {
        openURL("https://github.com/GobiCowboy/doubao-auto-send")
    }

    @objc private func openIssue() {
        openURL("https://github.com/GobiCowboy/doubao-auto-send/issues")
    }

    @objc private func checkForUpdates() {
        aboutStatusLabel.stringValue = L10n.text("aboutCheckingUpdates")

        guard let url = URL(string: "https://api.github.com/repos/GobiCowboy/doubao-auto-send/releases/latest") else {
            aboutStatusLabel.stringValue = L10n.text("aboutUpToDate")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AutoSend", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }

                guard error == nil, let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let tagName = json["tag_name"] as? String else {
                    self.aboutStatusLabel.stringValue = L10n.text("aboutUpdateFailed")
                    return
                }

                let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                let currentVersion = self.currentVersionString()

                if self.isNewerVersion(remoteVersion, than: currentVersion) {
                    self.aboutStatusLabel.stringValue = String(format: L10n.text("aboutUpdateAvailable"), remoteVersion)
                    self.presentUpdateAvailableAlert(version: remoteVersion)
                } else {
                    self.aboutStatusLabel.stringValue = L10n.text("aboutUpToDate")
                }
            }
        }.resume()
    }

    private func presentUpdateAvailableAlert(version: String) {
        let alert = NSAlert()
        alert.messageText = String(format: L10n.text("aboutUpdateAvailable"), version)
        alert.informativeText = L10n.text("aboutCheckingUpdates")
        alert.addButton(withTitle: L10n.text("aboutOpenReleases"))
        alert.addButton(withTitle: L10n.text("ok"))

        if alert.runModal() == .alertFirstButtonReturn {
            openURL("https://github.com/GobiCowboy/doubao-auto-send/releases/latest")
        }
    }

    private func isNewerVersion(_ remote: String, than current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let count = max(remoteParts.count, currentParts.count)
        for index in 0..<count {
            let remotePart = index < remoteParts.count ? remoteParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0
            if remotePart > currentPart { return true }
            if remotePart < currentPart { return false }
        }
        return false
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}
