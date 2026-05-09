import Cocoa
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowControllers: [ImageWindowController] = []
    private let logPath = "/tmp/pictclipping-viewer.log"

    private func log(_ msg: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(msg)\n"
        if let fh = FileHandle(forWritingAtPath: logPath) {
            fh.seekToEndOfFile()
            fh.write(Data(line.utf8))
            fh.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: Data(line.utf8))
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        log("applicationWillFinishLaunching")
        log("  args: \(ProcessInfo.processInfo.arguments)")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        log("applicationDidFinishLaunching")
        log("  userInfo keys: \(notification.userInfo?.keys.map { String(describing: $0) } ?? [])")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        log("openFile: \(filename)")
        return openViewer(for: URL(fileURLWithPath: filename))
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        log("openFiles: \(filenames)")
        for f in filenames { openViewer(for: URL(fileURLWithPath: f)) }
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        log("open urls: \(urls.map { $0.path })")
        for url in urls { openViewer(for: url) }
    }

    @discardableResult
    private func openViewer(for url: URL) -> Bool {
        log("openViewer: \(url.path)")
        log("  exists: \(FileManager.default.fileExists(atPath: url.path))")
        log("  readable: \(FileManager.default.isReadableFile(atPath: url.path))")

        if let data = try? Data(contentsOf: url) {
            log("  fileSize: \(data.count) bytes")
        } else {
            log("  ERROR: could not read file data")
        }

        guard let image = PictClippingParser.image(from: url) else {
            log("  ERROR: parser returned nil")
            return false
        }

        log("  image: \(Int(image.size.width))x\(Int(image.size.height))")

        let wc = ImageWindowController(image: image, sourceURL: url)
        wc.window?.delegate = self
        windowControllers.append(wc)
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        log("  window shown, total windows: \(windowControllers.count)")
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
        // Rasterize vector images (e.g. PDF) so NSImageView renders them
        let displayImage = ImageWindowController.rasterize(image)
        self.image = displayImage
        self.sourceURL = sourceURL

        let size = displayImage.size
        let maxDim: CGFloat = 800
        let scale = min(maxDim / max(size.width, 1), maxDim / max(size.height, 1), 1.0)
        let winSize = NSSize(width: max(size.width * scale, 200), height: max(size.height * scale, 200))

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: winSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = sourceURL.lastPathComponent
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 200, height: 200)

        super.init(window: window)

        // Toolbar after super.init (delegate is self)
        let toolbar = NSToolbar(identifier: "ViewerToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar

        // Use Auto Layout for reliable sizing
        let imageView = NSImageView()
        imageView.image = displayImage
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(imageView)

        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }
    }

    /// Rasterize an NSImage to a bitmap. PDF/PICT images are vector and may
    /// not render in NSImageView without rasterization.
    private static func rasterize(_ image: NSImage) -> NSImage {
        let size = image.size
        guard size.width > 0 && size.height > 0 else { return image }

        // Check if already a bitmap
        if image.representations.contains(where: { $0 is NSBitmapImageRep }) {
            return image
        }

        let bitmapImage = NSImage(size: size)
        bitmapImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        bitmapImage.unlockFocus()
        return bitmapImage
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
        let fmt = ImageExporter.format(for: url.pathExtension)
        if let data = ImageExporter.data(from: image, format: fmt) {
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
