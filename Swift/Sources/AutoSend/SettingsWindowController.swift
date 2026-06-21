import AppKit
import ServiceManagement

private final class SettingsBackgroundView: NSView {
    var onEffectiveAppearanceChange: (() -> Void)?

    override var isFlipped: Bool { true }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onEffectiveAppearanceChange?()
    }
}

final class SettingsWindowController: NSWindowController {
    private enum Metrics {
        static let contentWidth: CGFloat = 760
        static let horizontalInset: CGFloat = 28
    }

    private enum Palette {
        static func pageBackground(isDark: Bool) -> NSColor {
            isDark ? NSColor(calibratedWhite: 0.12, alpha: 1.0) : NSColor(calibratedWhite: 0.97, alpha: 1.0)
        }

        static func cardBackground(isDark: Bool) -> NSColor {
            isDark ? NSColor(calibratedWhite: 0.16, alpha: 1.0) : NSColor.white
        }

        static func cardBorder(isDark: Bool) -> NSColor {
            isDark ? NSColor(calibratedWhite: 0.32, alpha: 1.0) : NSColor(calibratedWhite: 0.84, alpha: 1.0)
        }

        static func divider(isDark: Bool) -> NSColor {
            isDark ? NSColor(calibratedWhite: 1.0, alpha: 0.10) : NSColor(calibratedWhite: 0.0, alpha: 0.08)
        }

        static func guideBorder(isDark: Bool) -> NSColor {
            isDark ? NSColor.systemBlue.withAlphaComponent(0.30) : NSColor.systemBlue.withAlphaComponent(0.24)
        }

        static func destructiveBorder(isDark: Bool) -> NSColor {
            isDark ? NSColor.systemRed.withAlphaComponent(0.28) : NSColor.systemRed.withAlphaComponent(0.22)
        }
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

    private let windowSize = NSSize(width: 900, height: 860)
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
    private let guideStepTwoCardView = NSView()
    private let guideStepTwoTitleLabel = NSTextField(labelWithString: "")
    private let guideStepTwoDetailLabel = NSTextField(labelWithString: "")
    private let guideStepTwoButton = NSButton(title: "", target: nil, action: nil)

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
    private var themeDividerViews: [NSView] = []
    private var themeAccentViews: [NSView] = []
    private weak var settingsScrollView: NSScrollView?
    private weak var settingsBackgroundView: SettingsBackgroundView?

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
        applyThemeColors()
        refreshLocalizedContent()
        refreshLaunchAtLoginState()
        refreshMenuBarIconState()
        refreshWorkflowState(restartRequired: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func refreshLocalizedContent() {
        window?.title = L10n.text("settingsTitle")

        titleLabel.stringValue = L10n.text("settingsIntroTitle")
        subtitleLabel.stringValue = L10n.text("settingsIntroBody")
        guideSectionLabel.stringValue = L10n.text("setupTitle")
        generalSectionLabel.stringValue = L10n.text("generalSection")
        languageLabel.stringValue = L10n.text("language")
        launchAtLoginLabel.stringValue = L10n.text("launchAtLogin")
        showMenuBarIconLabel.stringValue = L10n.text("menuBarIcon")
        permissionsSectionLabel.stringValue = L10n.text("permissionsSection")
        aboutSectionLabel.stringValue = L10n.text("aboutSection")
        advancedSectionLabel.stringValue = L10n.text("advancedSection")
        accessibilityTitleLabel.stringValue = L10n.text("accessibility")
        accessibilityDetailLabel.stringValue = L10n.text("accessibilityDetail")
        inputMonitoringTitleLabel.stringValue = L10n.text("inputMonitoring")
        inputMonitoringDetailLabel.stringValue = L10n.text("inputMonitoringDetail")
        inputMonitoringHintLabel.stringValue = L10n.text("inputMonitoringRestartHint")
        openAccessibilityButton.title = L10n.text("goToSettings")
        recheckButton.title = L10n.text("goToSettings")
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
        updateDetailLabel.stringValue = L10n.text("aboutUpdateDescription")
        quitTitleLabel.stringValue = L10n.text("quit")
        quitDetailLabel.stringValue = L10n.text("restartRequired")
        quitButton.title = L10n.text("quit")

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
        selectLanguage(AppState.shared.preferredLanguage)
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

        updateStatusPill(
            accessibilityStateLabel,
            text: permissionStateText(
                granted: accessibilityGranted,
                grantedText: L10n.text("accessibilityGranted"),
                missingText: L10n.text("accessibilityMissing")
            ),
            color: accessibilityGranted ? .systemGreen : .systemRed
        )

        updateStatusPill(
            inputMonitoringStateLabel,
            text: permissionStateText(
                granted: inputMonitoringGranted,
                grantedText: L10n.text("inputGranted"),
                missingText: L10n.text("inputMissing")
            ),
            color: inputMonitoringGranted ? .systemGreen : .systemRed
        )

        inputMonitoringHintLabel.isHidden = !accessibilityGranted || inputMonitoringGranted
        updateGuide(accessibilityGranted: accessibilityGranted, inputMonitoringGranted: inputMonitoringGranted)
        updatePermissionActionButton(openAccessibilityButton, granted: accessibilityGranted)
        updatePermissionActionButton(recheckButton, granted: inputMonitoringGranted)
    }

    private func configureWindow() {
        guard let window else { return }
        window.title = L10n.text("settingsTitle")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.center()
        window.setContentSize(windowSize)
        window.minSize = NSSize(width: 760, height: 680)
        window.backgroundColor = currentPageBackground()
        applyThemeColors()
    }

    private func makeContentView() -> NSView {
        let scrollView = NSScrollView(frame: NSRect(origin: .zero, size: windowSize))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        settingsScrollView = scrollView

        let contentView = SettingsBackgroundView(frame: NSRect(x: 0, y: 0, width: windowSize.width, height: 980))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = currentPageBackground().cgColor
        contentView.onEffectiveAppearanceChange = { [weak self] in
            self?.applyThemeColors()
            self?.refreshWorkflowState(restartRequired: self?.currentRestartRequired ?? false)
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        settingsBackgroundView = contentView
        scrollView.documentView = contentView

        setupTypographyAndControls()

        let headerStack = makeHeader()
        guideSectionHeaderRow = makeSectionHeader(guideSectionLabel)
        configureGuideCard()
        configureGuideStepTwoCard()
        configureGeneralCard()
        configurePermissionsCard()
        configureAboutCard()
        configureUpdateCard()
        configureAdvancedCard()

        let rootStack = NSStackView(views: [
            headerStack,
            guideSectionHeaderRow,
            guideCardView,
            guideStepTwoCardView,
            makeSectionHeader(permissionsSectionLabel),
            permissionsCardView,
            makeSectionHeader(generalSectionLabel),
            generalCardView,
            makeSectionHeader(aboutSectionLabel),
            aboutCardView,
            updateCardView,
            makeSectionHeader(advancedSectionLabel),
            advancedCardView,
        ])
        rootStack.orientation = .vertical
        rootStack.alignment = .width
        rootStack.spacing = 15
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(rootStack)
        let preferredWidth = rootStack.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -Metrics.horizontalInset * 2)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            rootStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rootStack.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: Metrics.horizontalInset),
            rootStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Metrics.horizontalInset),
            rootStack.widthAnchor.constraint(lessThanOrEqualToConstant: Metrics.contentWidth),
            preferredWidth,
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])

        return scrollView
    }

    private func applyThemeColors() {
        guard let window else { return }
        let isDark = isDarkAppearance()

        let pageBackground = Palette.pageBackground(isDark: isDark)
        let cardBackground = Palette.cardBackground(isDark: isDark)
        let cardBorder = Palette.cardBorder(isDark: isDark)
        let guideBorder = Palette.guideBorder(isDark: isDark)
        let destructiveBorder = Palette.destructiveBorder(isDark: isDark)
        let dividerColor = Palette.divider(isDark: isDark)

        window.backgroundColor = pageBackground
        window.contentView?.layer?.backgroundColor = pageBackground.cgColor

        settingsScrollView?.drawsBackground = true
        settingsScrollView?.backgroundColor = pageBackground
        settingsScrollView?.contentView.drawsBackground = true
        settingsScrollView?.contentView.backgroundColor = pageBackground

        settingsBackgroundView?.layer?.backgroundColor = pageBackground.cgColor

        [guideCardView, guideStepTwoCardView, generalCardView, permissionsCardView, aboutCardView, updateCardView, advancedCardView].forEach {
            $0.layer?.backgroundColor = cardBackground.cgColor
            $0.layer?.borderColor = cardBorder.cgColor
        }

        themeAccentViews.forEach {
            $0.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.10).cgColor
        }
        themeDividerViews.forEach {
            $0.layer?.backgroundColor = dividerColor.cgColor
        }

        guideCardView.layer?.borderColor = isGuidePulseActive ? guideBorder.cgColor : cardBorder.cgColor
        advancedCardView.layer?.borderColor = destructiveBorder.cgColor
    }

    private func isDarkAppearance() -> Bool {
        let appearance = window?.effectiveAppearance ?? NSApp.effectiveAppearance
        switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
        case .darkAqua:
            return true
        default:
            return false
        }
    }

    private func currentPageBackground() -> NSColor {
        Palette.pageBackground(isDark: isDarkAppearance())
    }

    private func setupTypographyAndControls() {
        headerIconView.image = AppIconProvider.appIcon() ?? NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        headerIconView.imageScaling = .scaleProportionallyDown
        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerIconView.widthAnchor.constraint(equalToConstant: 44),
            headerIconView.heightAnchor.constraint(equalToConstant: 44),
        ])

        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2

        [guideSectionLabel, permissionsSectionLabel, generalSectionLabel, aboutSectionLabel, advancedSectionLabel].forEach {
            $0.font = .systemFont(ofSize: 11, weight: .semibold)
            $0.textColor = .secondaryLabelColor
            $0.maximumNumberOfLines = 1
        }

        [languageLabel, launchAtLoginLabel, showMenuBarIconLabel, accessibilityTitleLabel, inputMonitoringTitleLabel, aboutVersionTitleLabel, aboutProjectTitleLabel, aboutIssueTitleLabel, quitTitleLabel].forEach {
            $0.font = .systemFont(ofSize: 15, weight: .regular)
            $0.textColor = .labelColor
            $0.maximumNumberOfLines = 1
        }
        showMenuBarIconLabel.stringValue = L10n.text("menuBarIcon")

        [accessibilityDetailLabel, inputMonitoringDetailLabel, inputMonitoringHintLabel, updateDetailLabel, quitDetailLabel, aboutStatusLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabelColor
            $0.maximumNumberOfLines = 2
            $0.lineBreakMode = .byWordWrapping
        }
        inputMonitoringHintLabel.textColor = .systemOrange

        guideTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        guideTitleLabel.textColor = .labelColor
        guideDetailLabel.font = .systemFont(ofSize: 13)
        guideDetailLabel.textColor = .secondaryLabelColor
        guideDetailLabel.maximumNumberOfLines = 3
        guideDetailLabel.lineBreakMode = .byWordWrapping

        styleRoundedButton(guideActionButton, imageName: "gearshape")
        styleRoundedButton(guideStepTwoButton, imageName: "arrow.up.right.square")
        styleRoundedButton(openAccessibilityButton, imageName: "lock.open")
        styleRoundedButton(recheckButton, imageName: "checkmark.circle")
        styleIconButton(openProjectButton, imageName: "arrow.up.right.square")
        styleIconButton(openIssueButton, imageName: "arrow.up.right.square")
        styleIconButton(checkUpdatesButton, imageName: "arrow.clockwise")
        styleDestructiveButton(quitButton)

        languagePopup.controlSize = .regular
        launchAtLoginSwitch.controlSize = .small
        showMenuBarIconSwitch.controlSize = .small
        [launchAtLoginSwitch, showMenuBarIconSwitch].forEach {
            $0.layer?.transform = CATransform3DMakeScale(0.88, 0.88, 1)
        }

        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(toggleLaunchAtLogin)
        showMenuBarIconSwitch.target = self
        showMenuBarIconSwitch.action = #selector(toggleMenuBarIcon)
        guideActionButton.target = self
        guideActionButton.action = #selector(openAccessibility)
        guideStepTwoButton.target = self
        guideStepTwoButton.action = #selector(openInputMonitoring)
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
    }

    private func makeHeader() -> NSStackView {
        let titleStack = NSStackView(views: [titleLabel, subtitleLabel])
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 3

        let leftStack = NSStackView(views: [headerIconView, titleStack])
        leftStack.orientation = .horizontal
        leftStack.alignment = .centerY
        leftStack.spacing = 12

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = NSStackView(views: [leftStack, spacer])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 2, right: 0)
        return stack
    }

    private func configureGuideCard() {
        let icon = iconView(named: "accessibility", size: 24, tint: .systemBlue)
        let iconContainer = NSView()
        iconContainer.wantsLayer = true
        iconContainer.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.10).cgColor
        iconContainer.layer?.cornerRadius = 8
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        themeAccentViews.append(iconContainer)
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 42),
            iconContainer.heightAnchor.constraint(equalToConstant: 42),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
        ])

        let textStack = NSStackView(views: [guideTitleLabel, guideDetailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5

        let leftStack = NSStackView(views: [iconContainer, textStack])
        leftStack.orientation = .horizontal
        leftStack.alignment = .top
        leftStack.spacing = 12

        let row = makeRow(left: leftStack, right: guideActionButton)
        row.alignment = .centerY
        configureCardContainer(guideCardView, content: row)
    }

    private func configureGuideStepTwoCard() {
        guideStepTwoTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        guideStepTwoTitleLabel.textColor = .labelColor
        guideStepTwoDetailLabel.font = .systemFont(ofSize: 13)
        guideStepTwoDetailLabel.textColor = .secondaryLabelColor
        guideStepTwoDetailLabel.maximumNumberOfLines = 3
        guideStepTwoDetailLabel.lineBreakMode = .byWordWrapping

        let icon = iconView(named: "keyboard", size: 20, tint: .systemBlue)
        let iconContainer = NSView()
        iconContainer.wantsLayer = true
        iconContainer.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.10).cgColor
        iconContainer.layer?.cornerRadius = 8
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        themeAccentViews.append(iconContainer)
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 42),
            iconContainer.heightAnchor.constraint(equalToConstant: 42),
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
        ])

        let textStack = NSStackView(views: [guideStepTwoTitleLabel, guideStepTwoDetailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5

        let leftStack = NSStackView(views: [iconContainer, textStack])
        leftStack.orientation = .horizontal
        leftStack.alignment = .top
        leftStack.spacing = 12

        let row = makeRow(left: leftStack, right: guideStepTwoButton)
        row.alignment = .centerY
        configureCardContainer(guideStepTwoCardView, content: row)
        guideStepTwoCardView.layer?.borderColor = Palette.cardBorder(isDark: isDarkAppearance()).cgColor
    }

    private func configureGeneralCard() {
        let rows = [
            makeSettingsRow(icon: "globe", title: languageLabel, detail: nil, trailing: languagePopup),
            makeDivider(),
            makeSettingsRow(icon: "power", title: launchAtLoginLabel, detail: nil, trailing: launchAtLoginSwitch),
            makeDivider(),
            makeSettingsRow(icon: "menubar.rectangle", title: showMenuBarIconLabel, detail: nil, trailing: showMenuBarIconSwitch),
        ]
        configureCardContainer(generalCardView, content: makeSectionStack(rows: rows))
    }

    private func configurePermissionsCard() {
        let accessibilityRow = makeSettingsRow(
            icon: "accessibility",
            title: accessibilityTitleLabel,
            detail: accessibilityDetailLabel,
            status: accessibilityStateLabel,
            trailing: openAccessibilityButton
        )
        let inputMonitoringRow = makeSettingsRow(
            icon: "keyboard",
            title: inputMonitoringTitleLabel,
            detail: inputMonitoringDetailLabel,
            status: inputMonitoringStateLabel,
            trailing: recheckButton
        )
        configureCardContainer(permissionsCardView, content: makeSectionStack(rows: [
            accessibilityRow,
            makeDivider(),
            inputMonitoringRow,
            inputMonitoringHintLabel,
        ], spacing: 8))
    }

    private func configureAboutCard() {
        aboutVersionValueLabel.font = .systemFont(ofSize: 13)
        aboutVersionValueLabel.textColor = .secondaryLabelColor

        let rows = [
            makeSettingsRow(icon: "info.circle", title: aboutVersionTitleLabel, detail: nil, trailing: aboutVersionValueLabel),
            makeDivider(),
            makeSettingsRow(icon: "link", title: aboutProjectTitleLabel, detail: nil, trailing: openProjectButton),
            makeDivider(),
            makeSettingsRow(icon: "bubble.left", title: aboutIssueTitleLabel, detail: nil, trailing: openIssueButton),
        ]
        configureCardContainer(aboutCardView, content: makeSectionStack(rows: rows))
    }

    private func configureUpdateCard() {
        updateTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        let textStack = NSStackView(views: [updateTitleLabel, updateDetailLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        configureCardContainer(updateCardView, content: makeSectionStack(rows: [
            makeRow(left: textStack, right: checkUpdatesButton),
            aboutStatusLabel,
        ], spacing: 8))
    }

    private func configureAdvancedCard() {
        let row = makeSettingsRow(icon: "power", title: quitTitleLabel, detail: quitDetailLabel, trailing: quitButton)
        configureCardContainer(advancedCardView, content: row, tint: .systemRed)
    }

    private func updateGuide(accessibilityGranted: Bool, inputMonitoringGranted: Bool) {
        let showStepOne = !accessibilityGranted
        let showStepTwo = accessibilityGranted && !inputMonitoringGranted

        guideSectionHeaderRow.isHidden = !(showStepOne || showStepTwo)
        guideCardView.isHidden = !showStepOne
        guideStepTwoCardView.isHidden = !showStepTwo

        setGuidePulseActive(showStepOne)

        guideTitleLabel.stringValue = L10n.text("step1Title")
        guideDetailLabel.stringValue = L10n.text("step1Detail")
        guideActionButton.title = L10n.text("goToSettings")

        guideStepTwoTitleLabel.stringValue = L10n.text("step2Title")
        guideStepTwoDetailLabel.stringValue = L10n.text("step2Detail")
        guideStepTwoButton.title = L10n.text("goToSettings")
    }

    private func setGuidePulseActive(_ active: Bool) {
        guard active != isGuidePulseActive else { return }
        isGuidePulseActive = active
        guideCardView.layer?.removeAnimation(forKey: "guidePulse")
        let borderColor = active ? Palette.guideBorder(isDark: isDarkAppearance()) : Palette.cardBorder(isDark: isDarkAppearance())
        guideCardView.layer?.borderColor = borderColor.cgColor
    }

    private func configureCardContainer(_ container: NSView, content: NSView, tint: NSColor? = nil) {
        container.wantsLayer = true
        container.layer?.backgroundColor = Palette.cardBackground(isDark: isDarkAppearance()).cgColor
        container.layer?.cornerRadius = 8
        container.layer?.borderWidth = 1
        container.layer?.borderColor = (tint == nil ? Palette.cardBorder(isDark: isDarkAppearance()) : Palette.destructiveBorder(isDark: isDarkAppearance())).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let paddedContent = NSView()
        paddedContent.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(paddedContent)
        paddedContent.addSubview(content)

        NSLayoutConstraint.activate([
            paddedContent.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            paddedContent.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            paddedContent.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            paddedContent.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            content.leadingAnchor.constraint(equalTo: paddedContent.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: paddedContent.trailingAnchor),
            content.topAnchor.constraint(equalTo: paddedContent.topAnchor),
            content.bottomAnchor.constraint(equalTo: paddedContent.bottomAnchor),
        ])
    }

    private func makeSettingsRow(icon: String, title: NSTextField, detail: NSTextField?, status: NSTextField? = nil, trailing: NSView) -> NSStackView {
        let imageView = iconView(named: icon, size: 17, tint: .secondaryLabelColor)

        let titleViews = [title] + [status].compactMap { $0 }
        let titleRow = NSStackView(views: titleViews)
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 9

        let textViews = [titleRow] + [detail].compactMap { $0 }
        let textStack = NSStackView(views: textViews)
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 5

        let leftStack = NSStackView(views: [imageView, textStack])
        leftStack.orientation = .horizontal
        leftStack.alignment = detail == nil ? .centerY : .top
        leftStack.spacing = 13

        let row = makeRow(left: leftStack, right: trailing)
        row.edgeInsets = NSEdgeInsets(top: detail == nil ? 8 : 10, left: 0, bottom: detail == nil ? 8 : 10, right: 0)
        return row
    }

    private func makeRow(left: NSView, right: NSView) -> NSStackView {
        let spacer = NSView()
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

    private func makeDivider() -> NSView {
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = Palette.divider(isDark: isDarkAppearance()).cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        themeDividerViews.append(divider)
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
        row.edgeInsets = NSEdgeInsets(top: 8, left: 2, bottom: -4, right: 2)
        label.alignment = .left
        return row
    }

    private func iconView(named name: String, size: CGFloat, tint: NSColor) -> NSImageView {
        let view = NSImageView()
        view.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        view.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        view.contentTintColor = tint
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 20),
            view.heightAnchor.constraint(equalToConstant: 20),
        ])
        return view
    }

    private func styleRoundedButton(_ button: NSButton, imageName: String) {
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.contentTintColor = nil
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
    }

    private func styleIconButton(_ button: NSButton, imageName: String) {
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.contentTintColor = .secondaryLabelColor
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
    }

    private func styleDestructiveButton(_ button: NSButton) {
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.contentTintColor = .systemRed
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func updateStatusPill(_ label: NSTextField, text: String, color: NSColor) {
        label.stringValue = text
        label.wantsLayer = true
        label.drawsBackground = true
        label.backgroundColor = color.withAlphaComponent(0.12)
        label.textColor = color
        label.alignment = .center
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.layer?.cornerRadius = 6
        label.layer?.masksToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        if label.constraints.first(where: { $0.identifier == "statusPillMinWidth" }) == nil {
            let width = label.widthAnchor.constraint(greaterThanOrEqualToConstant: 72)
            width.identifier = "statusPillMinWidth"
            width.isActive = true
        }
    }

    private func updatePermissionActionButton(_ button: NSButton, granted: Bool) {
        if granted {
            button.title = ""
            button.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
            button.imagePosition = .imageOnly
            button.isBordered = false
            button.focusRingType = .none
            button.contentTintColor = .systemGreen
        } else {
            button.title = L10n.text("goToSettings")
            button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
            button.imagePosition = .imageLeading
            button.isBordered = true
            button.focusRingType = .default
            button.contentTintColor = nil
        }
    }

    private func permissionStateText(granted: Bool, grantedText: String, missingText: String) -> String {
        granted ? grantedText : missingText
    }

    private func currentVersionString() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
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

                guard error == nil,
                      let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
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
