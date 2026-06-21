import AppKit

enum AppIconProvider {
    static func appIcon() -> NSImage? {
        loadIcon(named: "autosend")
    }

    static func statusBarIcon(triggered: Bool) -> NSImage? {
        let symbolName = triggered ? "bolt.fill" : "bolt"
        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold, scale: .medium)
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)?
            .copy() as? NSImage else {
            return nil
        }

        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }

    private static func loadIcon(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "icns") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
