import AppKit
import Foundation
import os.log

private let log = Logger(
    subsystem: "co.redscreen.pictclipping.viewer",
    category: "parser"
)

enum PictClippingParser {

    // MARK: - Public

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

    /// Extract an image from a plist dictionary (the raw file data parsed as bplist).
    static func imageFromPlist(_ plist: [String: Any]) -> NSImage? {
        guard let utiData = plist["UTI-Data"] as? [String: Any] else { return nil }
        return imageFromUTIData(utiData)
    }

    /// Extract an image from a UTI-Data dictionary.
    static func imageFromUTIData(_ utiData: [String: Any]) -> NSImage? {
        let preferred = [
            "public.tiff", "public.png", "public.jpeg",
            "com.adobe.pdf",    // Real Finder clippings often contain PDF
            "com.apple.pict",   // Legacy PICT (last resort — may report 0x0)
        ]
        for uti in preferred {
            if let d = utiData[uti] as? Data, let img = NSImage(data: d),
               img.size.width > 0 && img.size.height > 0 { return img }
        }
        // Fallback: try any key with valid, non-zero-dimension image data
        for (_, v) in utiData {
            if let d = v as? Data, let img = NSImage(data: d),
               img.size.width > 0 && img.size.height > 0 { return img }
        }
        // Last resort: accept 0x0 images (e.g. PICT) — set a default size
        for uti in preferred {
            if let d = utiData[uti] as? Data, let img = NSImage(data: d) {
                if img.size.width == 0 || img.size.height == 0 {
                    img.size = NSSize(width: 800, height: 600)
                }
                return img
            }
        }
        return nil
    }

    /// Scan raw data for a TIFF header and return its range.
    static func findTIFF(in data: Data) -> Range<Data.Index>? {
        let bytes = [UInt8](data)
        for i in 0..<max(0, bytes.count - 4) {
            let le = bytes[i] == 0x49 && bytes[i+1] == 0x49 && bytes[i+2] == 0x2A && bytes[i+3] == 0x00
            let be = bytes[i] == 0x4D && bytes[i+1] == 0x4D && bytes[i+2] == 0x00 && bytes[i+3] == 0x2A
            if le || be { return i..<data.count }
        }
        return nil
    }

    // MARK: - Data fork (binary plist)

    private static func imageFromDataFork(url: URL) -> NSImage? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: Any] else {
            return nil
        }
        return imageFromPlist(plist)
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
}
