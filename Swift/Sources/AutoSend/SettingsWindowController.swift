import AppKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {
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
    private let closeButton = NSButton(title: "", target: nil, action: nil)
    private let guideSectionLabel = NSTextField(labelWithString: "")
    private var guideSectionHeaderRow = NSStackView()
    private let guideCardView = NSView()
    private let guideTitleLabel = NSTextField(labelWithString: "")
    private let guideDetailLabel = NSTextField(labelWithString: "")
    private let guideActionButton = NSButton(title: "", target: nil, action: nil)

    private let generalSectionLabel = NSTextField(labelWithString: "")
    private let languageLabel = NSTextField(labelWithString: "")
    private let languagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let launchAtLoginLabel = NSTextField(labelWithString: "")
    private let launchAtLoginSwitch = NSSwitch()
    private let showMenuBarIconLabel = NSTextField(labelWithString: "")
    private let showMenuBarIconSwitch = NSSwitch()

    private let permissionsSectionLabel = NSTextField(labelWithString: "")
    private let accessibilityTitleLabel = NSTextField(labelWithString: "")
    private let accessibilityDetailLabel = NSTextField(labelWithString: "")
    private let accessibilityStateLabel = NSTextField(labelWithString: "")
    private let inputMonitoringTitleLabel = NSTextField(labelWithString: "")
    private let inputMonitoringDetailLabel = NSTextField(labelWithString: "")
    private let inputMonitoringStateLabel = NSTextField(labelWithString: "")
    private let inputMonitoringHintLabel = NSTextField(labelWithString: "")
    private let openAccessibilityButton = NSButton(title: "", target: nil, action: nil)
    private let recheckButton = NSButton(title: "", target: nil, action: nil)
    private let generalCardView = NSView()
    private let permissionsCardView = NSView()

    private let aboutSectionLabel = NSTextField(labelWithString: "")
    private let aboutVersionTitleLabel = NSTextField(labelWithString: "")
    private let aboutVersionValueLabel = NSTextField(labelWithString: "")
    private let aboutStatusLabel = NSTextField(labelWithString: "")
    private let aboutProjectTitleLabel = NSTextField(labelWithString: "")
    private let aboutIssueTitleLabel = NSTextField(labelWithString: "")
    private let openProjectButton = NSButton(title: "", target: nil, action: nil)
    private let openIssueButton = NSButton(title: "", target: nil, action: nil)
    private let checkUpdatesButton = NSButton(title: "", target: nil, action: nil)
    private let aboutCardView = NSView()
    private let updateTitleLabel = NSTextField(labelWithString: "")
    private let updateDetailLabel = NSTextField(labelWithString: "")
    private let updateCardView = NSView()
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
        permissionsSectionLabel.stringValue = L10n.text("permissionsSection")
        aboutSectionLabel.stringValue = L10n.text("aboutSection")
        advancedSectionLabel.stringValue = L10n.text("advancedSection")
        accessibilityTitleLabel.stringValue = L10n.text("accessibility")
        accessibilityDetailLabel.stringValue = L10n.text("accessibilityDetail")
        inputMonitoringTitleLabel.stringValue = L10n.text("inputMonitoring")
        inputMonitoringDetailLabel.stringValue = L10n.text("inputMonitoringDetail")
        inputMonitoringHintLabel.stringValue = L10n.text("inputMonitoringRestartHint")
        openAccessibilityButton.title = L10n.text("openAccessibilitySettings")
        recheckButton.title = L10n.text("recheckPermissions")
        aboutVersionTitleLabel.stringValue = L10n.text("aboutVersion")
        aboutVersionValueLabel.stringValue = currentVersionString()
        aboutStatusLabel.stringValue = ""
        aboutStatusLabel.isHidden = true
        aboutProjectTitleLabel.stringValue = L10n.text("aboutProject")
        aboutIssueTitleLabel.stringValue = L10n.text("aboutIssue")
        openProjectButton.title = ""
        openIssueButton.title = ""
        checkUpdatesButton.title = ""
        updateTitleLabel.stringValue = L10n.text("aboutCheckUpdates")
        updateDetailLabel.stringValue = "Stay up to date with the latest features and bug fixes."
        quitTitleLabel.stringValue = L10n.text("quit")
        quitDetailLabel.stringValue = L10n.text("restartRequired")
        quitButton.title = L10n.text("quit")
        closeButton.title = "×"

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
        launchAtLoginSwitch.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    func refreshMenuBarIconState() {
        showMenuBarIconSwitch.state = AppState.shared.showMenuBarIcon ? .on : .off
    }

    func refreshWorkflowState(restartRequired: Bool) {
        currentRestartRequired = restartRequired
        let accessibilityGranted = permissionManager.isAccessibilityGranted()
        let inputMonitoringGranted = permissionManager.isInputMonitoringGranted()

        accessibilityStateLabel.stringValue = permissionStateText(
            granted: accessibilityGranted,
            grantedText: L10n.text("accessibilityGranted"),
            missingText: L10n.text("accessibilityMissing")
        )
        accessibilityStateLabel.textColor = accessibilityGranted ? .systemGreen : .systemRed
        accessibilityStateLabel.backgroundColor = accessibilityGranted ? NSColor.systemGreen.withAlphaComponent(0.14) : NSColor.systemRed.withAlphaComponent(0.14)

        inputMonitoringStateLabel.stringValue = permissionStateText(
            granted: inputMonitoringGranted,
            grantedText: L10n.text("inputGranted"),
            missingText: L10n.text("inputMissing")
        )
        inputMonitoringStateLabel.textColor = inputMonitoringGranted ? .systemBlue : .systemRed
        inputMonitoringStateLabel.backgroundColor = inputMonitoringGranted ? NSColor.systemBlue.withAlphaComponent(0.14) : NSColor.systemRed.withAlphaComponent(0.14)
        inputMonitoringHintLabel.isHidden = inputMonitoringGranted

        updateGuide(accessibilityGranted: accessibilityGranted)
        updateSectionVisibility(accessibilityGranted: accessibilityGranted, inputMonitoringGranted: inputMonitoringGranted)
        openAccessibilityButton.title = accessibilityGranted ? L10n.text("openAccessibilitySettings") : L10n.text("grantAccess")
        recheckButton.title = inputMonitoringGranted ? L10n.text("recheckPermissions") : L10n.text("openInputMonitoringSettings")
    }

    private func updateGuide(accessibilityGranted: Bool) {
        guideSectionHeaderRow.isHidden = false
        guideCardView.isHidden = false
        guideTitleLabel.textColor = .labelColor
        setGuidePulseActive(!accessibilityGranted)

        guideTitleLabel.stringValue = L10n.text("step1Title")
        guideDetailLabel.attributedStringValue = attributedGuideDetail(
            text: L10n.text("step1Detail"),
            highlight: nil
        )
        guideActionButton.title = accessibilityGranted ? L10n.text("openAccessibilitySettings") : L10n.text("grantAccess")
        guideActionButton.target = self
        guideActionButton.action = #selector(openAccessibility)
        guideActionButton.isHidden = false
    }

    private func updateSectionVisibility(accessibilityGranted: Bool, inputMonitoringGranted: Bool) {
        openAccessibilityButton.isHidden = false
        recheckButton.isHidden = false
        inputMonitoringHintLabel.isHidden = !accessibilityGranted || inputMonitoringGranted
        recheckButton.contentTintColor = inputMonitoringGranted ? .systemBlue : .systemBlue
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
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
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

        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.font = .systemFont(ofSize: 20, weight: .regular)
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.contentTintColor = .labelColor
        closeButton.alignment = .center
        closeButton.translatesAutoresizingMaskIntoConstraints = false

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
        guideActionButton.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        guideActionButton.contentTintColor = .white
        guideActionButton.imagePosition = .imageLeading
        guideActionButton.wantsLayer = true
        guideActionButton.layer?.backgroundColor = NSColor.systemBlue.cgColor
        guideActionButton.layer?.cornerRadius = 12
        guideActionButton.layer?.masksToBounds = true

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

        let guideButtonStack = NSStackView(views: [guideActionButton])
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

        headerIconView.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        headerIconView.contentTintColor = .white
        headerIconView.imageScaling = .scaleProportionallyDown
        headerIconView.wantsLayer = true
        headerIconView.layer?.backgroundColor = NSColor.systemBlue.cgColor
        headerIconView.layer?.cornerRadius = 10
        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerIconView.widthAnchor.constraint(equalToConstant: 40),
            headerIconView.heightAnchor.constraint(equalToConstant: 40),
        ])

        [guideSectionLabel, generalSectionLabel, permissionsSectionLabel, aboutSectionLabel, advancedSectionLabel].forEach {
            $0.font = .systemFont(ofSize: 11, weight: .semibold)
            $0.textColor = .secondaryLabelColor
            $0.isHidden = false
        }

        [languageLabel, launchAtLoginLabel, showMenuBarIconLabel, accessibilityTitleLabel, inputMonitoringTitleLabel, aboutVersionTitleLabel, aboutProjectTitleLabel, aboutIssueTitleLabel, quitTitleLabel].forEach {
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
        stylePill(accessibilityStateLabel, textColor: .systemRed, backgroundColor: NSColor.systemRed.withAlphaComponent(0.14))
        stylePill(inputMonitoringStateLabel, textColor: .systemBlue, backgroundColor: NSColor.systemBlue.withAlphaComponent(0.14))

        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)

        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(toggleLaunchAtLogin)
        showMenuBarIconSwitch.target = self
        showMenuBarIconSwitch.action = #selector(toggleMenuBarIcon)

        openAccessibilityButton.target = self
        openAccessibilityButton.action = #selector(openAccessibility)
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

        [openAccessibilityButton, recheckButton].forEach {
            _ = rightButton($0, tint: .systemBlue)
        }
        [openProjectButton, openIssueButton, checkUpdatesButton, quitButton].forEach {
            _ = rightButton($0)
        }
        openProjectButton.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil)
        openIssueButton.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil)
        checkUpdatesButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        quitButton.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        [openProjectButton, openIssueButton, checkUpdatesButton].forEach {
            $0.contentTintColor = .secondaryLabelColor
        }
        quitButton.contentTintColor = .white
        quitButton.imagePosition = .imageLeading
        quitButton.wantsLayer = true
        quitButton.layer?.backgroundColor = NSColor.systemRed.cgColor
        quitButton.layer?.cornerRadius = 10
        quitButton.layer?.masksToBounds = true
        [openProjectButton, openIssueButton, checkUpdatesButton].forEach {
            $0.imagePosition = .imageOnly
        }
        checkUpdatesButton.wantsLayer = true
        checkUpdatesButton.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        checkUpdatesButton.layer?.borderWidth = 1
        checkUpdatesButton.layer?.borderColor = NSColor.systemBlue.cgColor
        checkUpdatesButton.layer?.cornerRadius = 10
        checkUpdatesButton.layer?.masksToBounds = true
        checkUpdatesButton.contentTintColor = .systemBlue

        let languageRow = makeRow(left: titleRow(icon: "globe", title: languageLabel), right: languagePopup)
        let launchRow = makeRow(left: titleRow(icon: "power", title: launchAtLoginLabel), right: launchAtLoginSwitch)
        let menuBarRow = makeRow(left: titleRow(icon: "eye", title: showMenuBarIconLabel), right: showMenuBarIconSwitch)
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
            right: recheckButton
        )
        let permissionsStack = makeSectionStack(rows: [
            accessibilityTopRow,
            makeDivider(),
            inputMonitoringTopRow,
            inputMonitoringHintLabel,
        ], spacing: 0)
        configureCardContainer(permissionsCardView, content: permissionsStack)

        let aboutVersionRow = makeRow(left: titleRow(icon: "info.circle", title: aboutVersionTitleLabel), right: aboutVersionValueLabel)
        aboutVersionValueLabel.textColor = .secondaryLabelColor
        let aboutProjectRow = makeRow(left: titleRow(icon: "link", title: aboutProjectTitleLabel), right: openProjectButton)
        let aboutIssueRow = makeRow(left: titleRow(icon: "bubble.left", title: aboutIssueTitleLabel), right: openIssueButton)
        let aboutStack = makeSectionStack(rows: [
            aboutVersionRow,
            makeDivider(),
            aboutProjectRow,
            makeDivider(),
            aboutIssueRow,
        ], spacing: 0)
        configureCardContainer(aboutCardView, content: aboutStack)

        let updateLeftStack = NSStackView(views: [updateTitleLabel, updateDetailLabel])
        updateLeftStack.orientation = .vertical
        updateLeftStack.alignment = .leading
        updateLeftStack.spacing = 4
        updateTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        updateDetailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        updateDetailLabel.textColor = .secondaryLabelColor
        updateDetailLabel.maximumNumberOfLines = 2

        let updateRow = makeRow(left: updateLeftStack, right: checkUpdatesButton)
        let updateStack = makeSectionStack(rows: [updateRow, aboutStatusLabel], spacing: 0)
        configureCardContainer(updateCardView, content: updateStack)

        let quitStack = makeRow(left: titleDetailRow(icon: "power", title: quitTitleLabel, detail: quitDetailLabel), right: quitButton)
        configureCardContainer(advancedCardView, content: quitStack)
        advancedCardView.wantsLayer = true
        advancedCardView.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.06).cgColor
        advancedCardView.layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.20).cgColor

        let titleStack = NSStackView(views: [titleLabel, subtitleLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 4

        let headerLeftStack = NSStackView(views: [headerIconView, titleStack])
        headerLeftStack.orientation = .horizontal
        headerLeftStack.alignment = .centerY
        headerLeftStack.spacing = 12

        let headerSpacer = NSView()
        headerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let headerStack = NSStackView(views: [headerLeftStack, headerSpacer, closeButton])
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.distribution = .fill
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
            updateCardView,
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

    private func stylePill(_ label: NSTextField, textColor: NSColor, backgroundColor: NSColor) {
        label.wantsLayer = true
        label.layer?.cornerRadius = 999
        label.layer?.masksToBounds = true
        label.drawsBackground = true
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.alignment = .center
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.maximumNumberOfLines = 1
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
        if permissionManager.isInputMonitoringGranted() {
            onRecheck()
        } else {
            onOpenInputMonitoringSettings()
        }
    }

    @objc private func restartApp() {
        onRestartApp()
    }

    @objc private func quitApp() {
        onQuitApp()
    }

    @objc private func closeWindow() {
        window?.close()
    }

    @objc private func openProject() {
        openURL("https://github.com/GobiCowboy/doubao-auto-send")
    }

    @objc private func openIssue() {
        openURL("https://github.com/GobiCowboy/doubao-auto-send/issues")
    }

    @objc private func checkForUpdates() {
        aboutStatusLabel.stringValue = L10n.text("aboutCheckingUpdates")
        aboutStatusLabel.isHidden = false

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
