import AppKit
import QuickLookUI
import os.log

private let log = Logger(
    subsystem: "co.redscreen.pictclipping.viewer.quicklook",
    category: "preview"
)

class PreviewViewController: NSViewController, QLPreviewingController {
    private let imageView: NSImageView = {
        let v = NSImageView()
        v.imageScaling = .scaleProportionallyUpOrDown
        v.imageAlignment = .alignCenter
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: root.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
        ])
        self.view = root
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        log.error("PREVIEW INVOKED: \(url.path, privacy: .public)")
        let image = PictClippingParser.image(from: url)
        log.error("IMAGE RESULT: \(image != nil ? "yes" : "nil", privacy: .public)")
        imageView.image = image
        handler(nil)
    }
}
