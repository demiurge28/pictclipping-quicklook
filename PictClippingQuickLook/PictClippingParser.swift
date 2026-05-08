import AppKit
import Foundation
import os.log

private let log = Logger(
    subsystem: "co.redscreen.pictclipping.viewer.quicklook",
    category: "parser"
)

enum PictClippingParser {

    static func image(from url: URL) -> NSImage? {
        if let img = imageFromDataFork(url: url) {
            log.info("Loaded from data fork: \(url.lastPathComponent, privacy: .public)")
            return img
        }
        if let img = imageFromResourceFork(url: url) {
            log.info("Loaded from resource fork: \(url.lastPathComponent, privacy: .public)")
            return img
        }
        log.error("No image found: \(url.lastPathComponent, privacy: .public)")
        return nil
    }

    // MARK: - Data fork (binary plist)

    private static func imageFromDataFork(url: URL) -> NSImage? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: Any],
              let utiData = plist["UTI-Data"] as? [String: Any] else {
            return nil
        }

        let preferred = ["public.tiff", "public.png", "public.jpeg", "com.apple.pict"]
        for uti in preferred {
            if let d = utiData[uti] as? Data, let img = NSImage(data: d) { return img }
        }
        for (_, v) in utiData {
            if let d = v as? Data, let img = NSImage(data: d) { return img }
        }
        return nil
    }

    // MARK: - Resource fork (xattr)

    private static func imageFromResourceFork(url: URL) -> NSImage? {
        guard let data = readXattr(path: url.path, name: "com.apple.ResourceFork") else {
            return nil
        }
        if let img = NSImage(data: data) { return img }
        if let range = findTIFF(in: data), let img = NSImage(data: data[range]) {
            return img
        }
        return nil
    }

    private static func readXattr(path: String, name: String) -> Data? {
        let size = getxattr(path, name, nil, 0, 0, 0)
        guard size > 0 else { return nil }
        var buf = [UInt8](repeating: 0, count: size)
        let read = getxattr(path, name, &buf, size, 0, 0)
        guard read == size else { return nil }
        return Data(buf)
    }

    private static func findTIFF(in data: Data) -> Range<Data.Index>? {
        let bytes = [UInt8](data)
        for i in 0..<max(0, bytes.count - 4) {
            let le = bytes[i] == 0x49 && bytes[i+1] == 0x49 && bytes[i+2] == 0x2A && bytes[i+3] == 0x00
            let be = bytes[i] == 0x4D && bytes[i+1] == 0x4D && bytes[i+2] == 0x00 && bytes[i+3] == 0x2A
            if le || be { return i..<data.count }
        }
        return nil
    }
}
