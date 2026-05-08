import AppKit
import QuickLookUI

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
        imageView.image = PictClippingParser.image(from: url)
        handler(nil)
    }
}
