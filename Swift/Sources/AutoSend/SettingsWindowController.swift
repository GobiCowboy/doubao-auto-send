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
    private let onToggleMenuBarIcon: () -> Void
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
    private var guideSectionHeaderRow = NSStackView()
    private let guideCardView = NSView()
    private let guideTitleLabel = NSTextField(labelWithString: "")
    private let guideDetailLabel = NSTextField(labelWithString: "")
    private let guideActionButton = NSButton(title: "", target: nil, action: nil)
    private let guideRestartButton = NSButton(title: "", target: nil, action: nil)

    private let generalSectionLabel = NSTextField(labelWithString: "")
    private let languageLabel = NSTextField(labelWithString: "")
    private let languagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let launchAtLoginLabel = NSTextField(labelWithString: "")
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let showMenuBarIconLabel = NSTextField(labelWithString: "")
    private let showMenuBarIconCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

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
    private let aboutProjectTitleLabel = NSTextField(labelWithString: "")
    private let aboutIssueTitleLabel = NSTextField(labelWithString: "")
    private let aboutCheckUpdatesTitleLabel = NSTextField(labelWithString: "")
    private let openProjectButton = NSButton(title: "", target: nil, action: nil)
    private let openIssueButton = NSButton(title: "", target: nil, action: nil)
    private let checkUpdatesButton = NSButton(title: "", target: nil, action: nil)
    private let aboutCardView = NSView()
    private let advancedSectionLabel = NSTextField(labelWithString: "")
    private let quitTitleLabel = NSTextField(labelWithString: "")
    private let quitDetailLabel = NSTextField(labelWithString: "")
    private let quitButton = NSButton(title: "", target: nil, action: nil)
    private let advancedCardView = NSView()
    private var isGuidePulseActive = false

    init(
        permissionManager: PermissionManager,
        onLanguageChanged: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping () -> Void,
        onToggleMenuBarIcon: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onOpenInputMonitoringSettings: @escaping () -> Void,
        onRecheck: @escaping () -> Void,
        onRestartApp: @escaping () -> Void,
        onQuitApp: @escaping () -> Void
    ) {
        self.permissionManager = permissionManager
        self.onLanguageChanged = onLanguageChanged
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
        self.onToggleMenuBarIcon = onToggleMenuBarIcon
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
        refreshMenuBarIconState()
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
        launchAtLoginLabel.stringValue = L10n.text("launchAtLogin")
        showMenuBarIconLabel.stringValue = L10n.text("showMenuBarIcon")
        launchAtLoginCheckbox.title = ""
        showMenuBarIconCheckbox.title = ""
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
        aboutProjectTitleLabel.stringValue = L10n.text("aboutProject")
        aboutIssueTitleLabel.stringValue = L10n.text("aboutIssue")
        aboutCheckUpdatesTitleLabel.stringValue = L10n.text("aboutCheckUpdates")
        openProjectButton.title = ""
        openIssueButton.title = ""
        checkUpdatesButton.title = ""
        quitTitleLabel.stringValue = L10n.text("quit")
        quitDetailLabel.stringValue = L10n.text("restartRequired")
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

    func refreshMenuBarIconState() {
        showMenuBarIconCheckbox.state = AppState.shared.showMenuBarIcon ? .on : .off
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
            guideSectionHeaderRow.isHidden = true
            guideCardView.isHidden = true
            setGuidePulseActive(false)
            return
        }

        guideSectionHeaderRow.isHidden = false
        guideCardView.isHidden = false
        guideTitleLabel.textColor = .labelColor
        setGuidePulseActive(stage == .accessibility)

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

    private func setGuidePulseActive(_ active: Bool) {
        guard active != isGuidePulseActive else { return }
        isGuidePulseActive = active
        guard let layer = guideCardView.layer else { return }

        layer.removeAnimation(forKey: "guidePulse")
        if active {
            let colorAnimation = CABasicAnimation(keyPath: "borderColor")
            colorAnimation.fromValue = NSColor.systemBlue.withAlphaComponent(0.35).cgColor
            colorAnimation.toValue = NSColor.systemBlue.cgColor
            colorAnimation.duration = 0.9
            colorAnimation.autoreverses = true
            colorAnimation.repeatCount = .infinity
            colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(colorAnimation, forKey: "guidePulse")
        } else {
            layer.borderColor = NSColor.separatorColor.cgColor
        }
    }

    private func configureWindow() {
        guard let window else { return }
        window.title = L10n.text("settingsTitle")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.setContentSize(NSSize(width: 920, height: 920))
        window.minSize = NSSize(width: 860, height: 760)
        window.isMovableByWindowBackground = true
    }

    private func makeContentView() -> NSView {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 920, height: 920))
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 920, height: 1400))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView

        func iconView(named name: String) -> NSImageView {
            let view = NSImageView()
            view.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            view.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            view.contentTintColor = .secondaryLabelColor
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 18),
                view.heightAnchor.constraint(equalToConstant: 18),
            ])
            return view
        }

        func titleRow(icon: String, title: NSTextField) -> NSStackView {
            let stack = NSStackView(views: [iconView(named: icon), title])
            stack.orientation = .horizontal
            stack.alignment = .centerY
            stack.spacing = 10
            stack.translatesAutoresizingMaskIntoConstraints = false
            return stack
        }

        func titleDetailRow(icon: String, title: NSTextField, detail: NSTextField, status: NSTextField? = nil) -> NSStackView {
            if let status {
                status.textColor = .systemRed
                status.font = .systemFont(ofSize: 10, weight: .semibold)
            }

            let topRow = NSStackView(views: [iconView(named: icon), title, status].compactMap { $0 })
            topRow.orientation = .horizontal
            topRow.alignment = .centerY
            topRow.spacing = 10

            let leftStack = NSStackView(views: [topRow, detail])
            leftStack.orientation = .vertical
            leftStack.alignment = .leading
            leftStack.spacing = 6
            leftStack.translatesAutoresizingMaskIntoConstraints = false
            return leftStack
        }

        func rightButton(_ button: NSButton, tint: NSColor = .labelColor) -> NSButton {
            button.bezelStyle = .inline
            button.isBordered = false
            button.imagePosition = .imageTrailing
            button.contentTintColor = tint
            button.alignment = .right
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }

        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.lineBreakMode = .byWordWrapping

        guideTitleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        guideTitleLabel.textColor = .systemBlue
        guideDetailLabel.font = .systemFont(ofSize: 16, weight: .medium)
        guideDetailLabel.textColor = .labelColor
        guideDetailLabel.maximumNumberOfLines = 0
        guideDetailLabel.lineBreakMode = .byWordWrapping

        guideActionButton.target = self
        guideActionButton.action = #selector(openAccessibility)
        guideActionButton.bezelStyle = .rounded
        guideActionButton.controlSize = .large
        guideActionButton.font = .systemFont(ofSize: 15, weight: .medium)
        guideRestartButton.target = self
        guideRestartButton.action = #selector(restartApp)
        guideRestartButton.bezelStyle = .rounded
        guideRestartButton.controlSize = .large
        guideRestartButton.font = .systemFont(ofSize: 15, weight: .medium)

        guideSectionLabel.isHidden = true
        guideSectionHeaderRow.isHidden = true
        guideCardView.isHidden = true
        guideCardView.wantsLayer = true
        guideCardView.layer?.cornerRadius = 16
        guideCardView.layer?.borderWidth = 1.5
        guideCardView.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.35).cgColor
        guideCardView.layer?.shadowColor = NSColor.systemBlue.cgColor
        guideCardView.layer?.shadowOpacity = 0.08
        guideCardView.layer?.shadowRadius = 14
        guideCardView.layer?.shadowOffset = .zero

        let guideLeftStack = NSStackView(views: [guideTitleLabel, guideDetailLabel])
        guideLeftStack.orientation = .vertical
        guideLeftStack.alignment = .leading
        guideLeftStack.spacing = 14

        let guideButtonStack = NSStackView(views: [guideActionButton, guideRestartButton])
        guideButtonStack.orientation = .vertical
        guideButtonStack.alignment = .trailing
        guideButtonStack.spacing = 10

        let guideRow = makeRow(left: guideLeftStack, right: guideButtonStack)
        guideRow.alignment = .top
        let guideStack = makeSectionStack(rows: [guideRow], spacing: 0)
        configureCardContainer(guideCardView, content: guideStack)
        guideCardView.layer?.cornerRadius = 16
        guideCardView.layer?.borderWidth = 1.5
        guideCardView.layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.35).cgColor
        guideCardView.layer?.shadowColor = NSColor.systemBlue.cgColor
        guideCardView.layer?.shadowOpacity = 0.08
        guideCardView.layer?.shadowRadius = 14
        guideCardView.layer?.shadowOffset = .zero

        headerIconView.image = AppIconProvider.appIcon()
        headerIconView.imageScaling = .scaleProportionallyDown
        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerIconView.widthAnchor.constraint(equalToConstant: 44),
            headerIconView.heightAnchor.constraint(equalToConstant: 44),
        ])

        [guideSectionLabel, generalSectionLabel, permissionsSectionLabel, aboutSectionLabel, advancedSectionLabel].forEach {
            $0.font = .systemFont(ofSize: 11, weight: .semibold)
            $0.textColor = .secondaryLabelColor
            $0.isHidden = false
        }

        [languageLabel, launchAtLoginLabel, showMenuBarIconLabel, accessibilityTitleLabel, inputMonitoringTitleLabel, aboutVersionTitleLabel, aboutProjectTitleLabel, aboutIssueTitleLabel, aboutCheckUpdatesTitleLabel, quitTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 14, weight: .medium)
        }

        [accessibilityDetailLabel, inputMonitoringDetailLabel, inputMonitoringHintLabel, aboutStatusLabel, subtitleLabel].forEach {
            $0.font = .systemFont(ofSize: 12, weight: .regular)
            $0.textColor = .secondaryLabelColor
            $0.maximumNumberOfLines = 0
        }

        inputMonitoringHintLabel.textColor = .systemRed
        quitDetailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        quitDetailLabel.textColor = .secondaryLabelColor
        [accessibilityStateLabel, inputMonitoringStateLabel].forEach {
            $0.font = .systemFont(ofSize: 10, weight: .semibold)
            $0.textColor = .systemRed
        }

        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)

        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(toggleLaunchAtLogin)
        launchAtLoginCheckbox.title = ""
        showMenuBarIconCheckbox.target = self
        showMenuBarIconCheckbox.action = #selector(toggleMenuBarIcon)
        showMenuBarIconCheckbox.title = ""

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

        [openAccessibilityButton, openInputMonitoringButton, recheckButton].forEach {
            _ = rightButton($0, tint: .systemBlue)
        }
        [openProjectButton, openIssueButton, checkUpdatesButton, quitButton].forEach {
            _ = rightButton($0)
        }
        openProjectButton.image = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
        openIssueButton.image = NSImage(systemSymbolName: "exclamationmark.bubble", accessibilityDescription: nil)
        checkUpdatesButton.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        quitButton.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitButton.contentTintColor = .systemRed
        [openProjectButton, openIssueButton, checkUpdatesButton].forEach {
            $0.imagePosition = .imageOnly
        }

        let languageRow = makeRow(left: titleRow(icon: "globe", title: languageLabel), right: languagePopup)
        let launchRow = makeRow(left: titleRow(icon: "power", title: launchAtLoginLabel), right: launchAtLoginCheckbox)
        let menuBarRow = makeRow(left: titleRow(icon: "eye", title: showMenuBarIconLabel), right: showMenuBarIconCheckbox)
        let generalStack = makeSectionStack(rows: [languageRow, makeDivider(), launchRow, makeDivider(), menuBarRow], spacing: 0)
        configureCardContainer(generalCardView, content: generalStack)

        let accessibilityTopRow = makeRow(
            left: titleDetailRow(
                icon: "accessibility",
                title: accessibilityTitleLabel,
                detail: accessibilityDetailLabel,
                status: accessibilityStateLabel
            ),
            right: openAccessibilityButton
        )
        let inputMonitoringTopRow = makeRow(
            left: titleDetailRow(
                icon: "keyboard",
                title: inputMonitoringTitleLabel,
                detail: inputMonitoringDetailLabel,
                status: inputMonitoringStateLabel
            ),
            right: openInputMonitoringButton
        )
        let permissionsFooterRow = makeRow(left: NSView(), right: recheckButton)
        let permissionsStack = makeSectionStack(rows: [
            accessibilityTopRow,
            makeDivider(),
            inputMonitoringTopRow,
            inputMonitoringHintLabel,
            permissionsFooterRow,
        ], spacing: 0)
        configureCardContainer(permissionsCardView, content: permissionsStack)

        let aboutVersionRow = makeRow(left: titleRow(icon: "info.circle", title: aboutVersionTitleLabel), right: aboutVersionValueLabel)
        aboutVersionValueLabel.textColor = .secondaryLabelColor
        let aboutProjectRow = makeRow(left: titleRow(icon: "link", title: aboutProjectTitleLabel), right: openProjectButton)
        let aboutIssueRow = makeRow(left: titleRow(icon: "bubble.left", title: aboutIssueTitleLabel), right: openIssueButton)
        let aboutUpdatesRow = makeRow(left: titleRow(icon: "arrow.clockwise", title: aboutCheckUpdatesTitleLabel), right: checkUpdatesButton)
        let aboutStack = makeSectionStack(rows: [
            aboutVersionRow,
            makeDivider(),
            aboutProjectRow,
            makeDivider(),
            aboutIssueRow,
            makeDivider(),
            aboutUpdatesRow,
            aboutStatusLabel,
        ], spacing: 0)
        configureCardContainer(aboutCardView, content: aboutStack)

        let quitStack = makeRow(left: titleDetailRow(icon: "power", title: quitTitleLabel, detail: quitDetailLabel), right: quitButton)
        configureCardContainer(advancedCardView, content: quitStack)

        let titleStack = NSStackView(views: [titleLabel, subtitleLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let headerStack = NSStackView(views: [headerIconView, titleStack])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 12

        guideSectionHeaderRow = makeSectionHeader(guideSectionLabel)

        let rootStack = NSStackView(views: [
            headerStack,
            guideSectionHeaderRow,
            guideCardView,
            makeSectionHeader(generalSectionLabel),
            generalCardView,
            makeSectionHeader(permissionsSectionLabel),
            permissionsCardView,
            makeSectionHeader(aboutSectionLabel),
            aboutCardView,
            makeSectionHeader(advancedSectionLabel),
            advancedCardView,
        ])
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 22
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.setHuggingPriority(.defaultLow, for: .horizontal)

        contentView.addSubview(rootStack)
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -26),
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

    private func makeRow(left: NSView, right: NSView) -> NSStackView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [left, spacer, right])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 12
        left.setContentHuggingPriority(.defaultLow, for: .horizontal)
        left.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        right.setContentHuggingPriority(.required, for: .horizontal)
        right.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
    }

    private func makeDivider() -> NSBox {
        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }

    private func makeSectionStack(rows: [NSView], spacing: CGFloat = 0) -> NSStackView {
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func makeSectionHeader(_ label: NSTextField) -> NSStackView {
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [label, spacer])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.spacing = 8
        label.alignment = .left
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
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

    @objc private func toggleMenuBarIcon() {
        onToggleMenuBarIcon()
        refreshMenuBarIconState()
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
