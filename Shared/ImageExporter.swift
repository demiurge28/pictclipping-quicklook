import AppKit

enum ImageExporter {

    enum Format: String, CaseIterable {
        case png, jpeg, tiff, bmp, gif

        var fileType: NSBitmapImageRep.FileType {
            switch self {
            case .png:  return .png
            case .jpeg: return .jpeg
            case .tiff: return .tiff
            case .bmp:  return .bmp
            case .gif:  return .gif
            }
        }
    }

    /// Convert an NSImage to the specified format.
    static func data(from image: NSImage, format: Format, jpegQuality: Double = 0.9) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }

        let props: [NSBitmapImageRep.PropertyKey: Any] = format == .jpeg
            ? [.compressionFactor: jpegQuality]
            : [:]

        return rep.representation(using: format.fileType, properties: props)
    }

    /// Determine format from a file extension string.
    static func format(for pathExtension: String) -> Format {
        switch pathExtension.lowercased() {
        case "jpg", "jpeg": return .jpeg
        case "tiff", "tif": return .tiff
        case "bmp":         return .bmp
        case "gif":         return .gif
        default:            return .png
        }
    }
}
