import Cocoa
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowControllers: [ImageWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        return openViewer(for: url)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for f in filenames { _ = openViewer(for: URL(fileURLWithPath: f)) }
    }

    private func openViewer(for url: URL) -> Bool {
        guard let image = PictClippingParser.image(from: url) else { return false }
        let wc = ImageWindowController(image: image, sourceURL: url)
        wc.window?.delegate = self
        windowControllers.append(wc)
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windowControllers.removeAll { $0.window === window }
    }
}

// MARK: - Window Controller

class ImageWindowController: NSWindowController {
    private let image: NSImage
    private let sourceURL: URL

    init(image: NSImage, sourceURL: URL) {
        self.image = image
        self.sourceURL = sourceURL

        let size = image.size
        let maxDim: CGFloat = 800
        let scale = min(maxDim / max(size.width, 1), maxDim / max(size.height, 1), 1.0)
        let winSize = NSSize(width: size.width * scale, height: size.height * scale)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: winSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = sourceURL.lastPathComponent
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let imageView = NSImageView(frame: window.contentView!.bounds)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(imageView)

        // Toolbar with export button
        let toolbar = NSToolbar(identifier: "ViewerToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc func exportImage(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = sourceURL.deletingPathExtension().lastPathComponent
        panel.allowedContentTypes = [
            .png, .jpeg, .tiff, .bmp, .gif,
        ]
        panel.allowsOtherFileTypes = false
        panel.canSelectHiddenExtension = true

        guard let window = self.window else { return }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else { return }
            self.saveImage(to: url)
        }
    }

    private func saveImage(to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return }

        let ext = url.pathExtension.lowercased()
        let fileType: NSBitmapImageRep.FileType
        switch ext {
        case "jpg", "jpeg": fileType = .jpeg
        case "tiff", "tif": fileType = .tiff
        case "bmp":         fileType = .bmp
        case "gif":         fileType = .gif
        default:            fileType = .png
        }

        let props: [NSBitmapImageRep.PropertyKey: Any] = fileType == .jpeg
            ? [.compressionFactor: 0.9]
            : [:]

        if let data = rep.representation(using: fileType, properties: props) {
            try? data.write(to: url)
        }
    }
}

// MARK: - Toolbar

private let exportItemID = NSToolbarItem.Identifier("export")

extension ImageWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [exportItemID, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, exportItemID]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == exportItemID else { return nil }
        let item = NSToolbarItem(itemIdentifier: exportItemID)
        item.label = "Export"
        item.toolTip = "Export as PNG, JPEG, TIFF, BMP, or GIF"
        item.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Export")
        item.target = self
        item.action = #selector(exportImage(_:))
        return item
    }
}
