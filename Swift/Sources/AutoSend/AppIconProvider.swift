import AppKit

enum AppIconProvider {
    static func appIcon() -> NSImage? {
        loadIcon(named: "autosend")
    }

    static func statusBarIcon(triggered: Bool) -> NSImage? {
        guard let image = appIcon()?.copy() as? NSImage else {
            return nil
        }

        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = false
        return image
    }

    private static func loadIcon(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "icns") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
