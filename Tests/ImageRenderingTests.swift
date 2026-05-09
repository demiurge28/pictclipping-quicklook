import XCTest
import AppKit
@testable import PictClippingViewer

private func makeTestImage(width: Int = 50, height: Int = 50) -> NSImage {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    NSColor.green.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    img.unlockFocus()
    return img
}

private func tmpURL(_ ext: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(ext)
}

// MARK: - ImageWindowController Tests

final class ImageWindowControllerTests: XCTestCase {

    func testWindowCreatedWithCorrectTitle() {
        let img = makeTestImage()
        let url = URL(fileURLWithPath: "/tmp/sample.pictClipping")
        let wc = ImageWindowController(image: img, sourceURL: url)
        XCTAssertEqual(wc.window?.title, "sample.pictClipping")
    }

    func testWindowSizedToImage() {
        let img = makeTestImage(width: 200, height: 100)
        let url = URL(fileURLWithPath: "/tmp/test.pictClipping")
        let wc = ImageWindowController(image: img, sourceURL: url)
        // contentRect is 200x100 but contentView may be taller due to toolbar
        let contentRect = wc.window!.contentRect(forFrameRect: wc.window!.frame)
        XCTAssertEqual(Int(contentRect.width), 200)
        // Image view should fill the content view width
        let imageViews = wc.window!.contentView!.subviews.compactMap { $0 as? NSImageView }
        XCTAssertEqual(Int(imageViews.first!.frame.width), Int(wc.window!.contentView!.bounds.width))
    }

    func testWindowCapsAtMaxDimension() {
        let img = makeTestImage(width: 2000, height: 1000)
        let url = URL(fileURLWithPath: "/tmp/big.pictClipping")
        let wc = ImageWindowController(image: img, sourceURL: url)
        let size = wc.window!.contentView!.bounds.size
        // Max 800, so 2000x1000 scaled by 0.4 -> 800x400
        XCTAssertLessThanOrEqual(Int(size.width), 800)
        XCTAssertLessThanOrEqual(Int(size.height), 800)
    }

    func testWindowContainsImageView() {
        let img = makeTestImage()
        let url = URL(fileURLWithPath: "/tmp/test.pictClipping")
        let wc = ImageWindowController(image: img, sourceURL: url)
        let imageViews = wc.window!.contentView!.subviews.compactMap { $0 as? NSImageView }
        XCTAssertEqual(imageViews.count, 1)
        XCTAssertNotNil(imageViews.first?.image)
    }

    func testWindowHasToolbar() {
        let img = makeTestImage()
        let url = URL(fileURLWithPath: "/tmp/test.pictClipping")
        let wc = ImageWindowController(image: img, sourceURL: url)
        XCTAssertNotNil(wc.window?.toolbar)
    }
}

// MARK: - ImageExporter Tests

final class ImageExporterTests: XCTestCase {

    // MARK: - Format detection

    func testFormatFromExtensionPNG() {
        XCTAssertEqual(ImageExporter.format(for: "png"), .png)
    }

    func testFormatFromExtensionJPEG() {
        XCTAssertEqual(ImageExporter.format(for: "jpeg"), .jpeg)
        XCTAssertEqual(ImageExporter.format(for: "jpg"), .jpeg)
        XCTAssertEqual(ImageExporter.format(for: "JPG"), .jpeg)
    }

    func testFormatFromExtensionTIFF() {
        XCTAssertEqual(ImageExporter.format(for: "tiff"), .tiff)
        XCTAssertEqual(ImageExporter.format(for: "tif"), .tiff)
    }

    func testFormatFromExtensionBMP() {
        XCTAssertEqual(ImageExporter.format(for: "bmp"), .bmp)
    }

    func testFormatFromExtensionGIF() {
        XCTAssertEqual(ImageExporter.format(for: "gif"), .gif)
    }

    func testFormatFromUnknownExtensionDefaultsToPNG() {
        XCTAssertEqual(ImageExporter.format(for: "webp"), .png)
        XCTAssertEqual(ImageExporter.format(for: ""), .png)
    }

    // MARK: - Export data

    func testExportPNG() {
        let img = makeTestImage()
        let data = ImageExporter.data(from: img, format: .png)
        XCTAssertNotNil(data)
        // PNG magic: 89 50 4E 47
        XCTAssertEqual(data?[0], 0x89)
        XCTAssertEqual(data?[1], 0x50) // P
        XCTAssertEqual(data?[2], 0x4E) // N
        XCTAssertEqual(data?[3], 0x47) // G
    }

    func testExportJPEG() {
        let img = makeTestImage()
        let data = ImageExporter.data(from: img, format: .jpeg)
        XCTAssertNotNil(data)
        // JPEG magic: FF D8 FF
        XCTAssertEqual(data?[0], 0xFF)
        XCTAssertEqual(data?[1], 0xD8)
    }

    func testExportTIFF() {
        let img = makeTestImage()
        let data = ImageExporter.data(from: img, format: .tiff)
        XCTAssertNotNil(data)
        // TIFF: II or MM
        let first = data?[0]
        XCTAssertTrue(first == 0x49 || first == 0x4D, "Should start with TIFF magic")
    }

    func testExportBMP() {
        let img = makeTestImage()
        let data = ImageExporter.data(from: img, format: .bmp)
        XCTAssertNotNil(data)
        // BMP magic: 42 4D (BM)
        XCTAssertEqual(data?[0], 0x42)
        XCTAssertEqual(data?[1], 0x4D)
    }

    func testExportGIF() {
        let img = makeTestImage()
        let data = ImageExporter.data(from: img, format: .gif)
        XCTAssertNotNil(data)
        // GIF magic: 47 49 46 (GIF)
        XCTAssertEqual(data?[0], 0x47)
        XCTAssertEqual(data?[1], 0x49)
        XCTAssertEqual(data?[2], 0x46)
    }

    // MARK: - Round-trip: export then reimport

    func testRoundTripPNG() {
        let original = makeTestImage(width: 30, height: 20)
        let data = ImageExporter.data(from: original, format: .png)!
        let reloaded = NSImage(data: data)
        XCTAssertNotNil(reloaded)
        XCTAssertEqual(Int(reloaded!.size.width), 30)
        XCTAssertEqual(Int(reloaded!.size.height), 20)
    }

    func testRoundTripJPEG() {
        let original = makeTestImage(width: 40, height: 40)
        let data = ImageExporter.data(from: original, format: .jpeg)!
        let reloaded = NSImage(data: data)
        XCTAssertNotNil(reloaded)
        XCTAssertEqual(Int(reloaded!.size.width), 40)
    }

    // MARK: - End-to-end: pictClipping → parse → export → verify

    func testEndToEndPictClippingToExport() {
        // Create a pictClipping file
        let original = makeTestImage(width: 60, height: 40)
        let tiff = original.tiffRepresentation!
        let plist: [String: Any] = ["UTI-Data": ["public.tiff": tiff]]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        let srcURL = tmpURL("pictClipping")
        try! plistData.write(to: srcURL)
        defer { try? FileManager.default.removeItem(at: srcURL) }

        // Parse
        let image = PictClippingParser.image(from: srcURL)
        XCTAssertNotNil(image)

        // Export as PNG
        let pngData = ImageExporter.data(from: image!, format: .png)
        XCTAssertNotNil(pngData)

        // Write and re-read
        let dstURL = tmpURL("png")
        try! pngData!.write(to: dstURL)
        defer { try? FileManager.default.removeItem(at: dstURL) }

        let exported = NSImage(contentsOf: dstURL)
        XCTAssertNotNil(exported)
        XCTAssertEqual(Int(exported!.size.width), 60)
        XCTAssertEqual(Int(exported!.size.height), 40)
    }
}
