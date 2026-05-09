import XCTest
import AppKit
@testable import PictClippingViewer

// MARK: - Helpers

/// Generate a minimal valid PNG as raw bytes.
private func makeTestPNG(width: Int = 4, height: Int = 4, r: UInt8 = 255, g: UInt8 = 0, b: UInt8 = 0) -> Data {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    NSColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}

/// Generate a minimal valid TIFF as raw bytes.
private func makeTestTIFF(width: Int = 4, height: Int = 4) -> Data {
    let img = NSImage(size: NSSize(width: width, height: height))
    img.lockFocus()
    NSColor.blue.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    img.unlockFocus()
    return img.tiffRepresentation!
}

/// Write a bplist pictClipping file to a temp path.
private func writePictClipping(_ plist: [String: Any]) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("pictClipping")
    let data = try! PropertyListSerialization.data(
        fromPropertyList: plist, format: .binary, options: 0
    )
    try! data.write(to: url)
    return url
}

// MARK: - Tests

final class PictClippingParserTests: XCTestCase {

    // MARK: - Data fork: UTI-Data with public.png

    func testDataForkWithPNG() {
        let png = makeTestPNG()
        let url = writePictClipping(["UTI-Data": ["public.png": png]])
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNotNil(image, "Should extract image from public.png in UTI-Data")
    }

    // MARK: - Data fork: UTI-Data with public.tiff

    func testDataForkWithTIFF() {
        let tiff = makeTestTIFF()
        let url = writePictClipping(["UTI-Data": ["public.tiff": tiff]])
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNotNil(image, "Should extract image from public.tiff in UTI-Data")
    }

    // MARK: - Data fork: UTI-Data with public.jpeg

    func testDataForkWithJPEG() {
        let png = makeTestPNG()
        let rep = NSBitmapImageRep(data: png)!
        let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!
        let url = writePictClipping(["UTI-Data": ["public.jpeg": jpeg]])
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNotNil(image, "Should extract image from public.jpeg in UTI-Data")
    }

    // MARK: - Data fork: TIFF preferred over PNG

    func testTIFFPreferredOverPNG() {
        let tiff = makeTestTIFF(width: 10, height: 10)
        let png = makeTestPNG(width: 5, height: 5)
        let utiData: [String: Any] = ["public.tiff": tiff, "public.png": png]

        let image = PictClippingParser.imageFromUTIData(utiData)
        XCTAssertNotNil(image)
        // TIFF is preferred, so the image size should match the TIFF (10x10)
        XCTAssertEqual(Int(image!.size.width), 10, "TIFF should be preferred over PNG")
    }

    // MARK: - Data fork: multiple UTIs with unknown keys

    func testFallbackToUnknownUTIKey() {
        let png = makeTestPNG()
        let utiData: [String: Any] = ["com.example.custom-image": png]

        let image = PictClippingParser.imageFromUTIData(utiData)
        XCTAssertNotNil(image, "Should fall back to any key with valid image data")
    }

    // MARK: - Data fork: missing UTI-Data key

    func testMissingUTIDataKey() {
        let plist: [String: Any] = ["SomeOtherKey": "value"]
        let image = PictClippingParser.imageFromPlist(plist)
        XCTAssertNil(image, "Should return nil when UTI-Data is missing")
    }

    // MARK: - Data fork: empty UTI-Data dictionary

    func testEmptyUTIData() {
        let utiData: [String: Any] = [:]
        let image = PictClippingParser.imageFromUTIData(utiData)
        XCTAssertNil(image, "Should return nil for empty UTI-Data")
    }

    // MARK: - Data fork: UTI-Data with non-image data

    func testUTIDataWithInvalidImageData() {
        let utiData: [String: Any] = ["public.tiff": Data([0x00, 0x01, 0x02, 0x03])]
        let image = PictClippingParser.imageFromUTIData(utiData)
        XCTAssertNil(image, "Should return nil when image data is invalid")
    }

    // MARK: - Data fork: UTI-Data with string values (not Data)

    func testUTIDataWithStringValues() {
        let utiData: [String: Any] = ["public.utf8-plain-text": "Hello world"]
        let image = PictClippingParser.imageFromUTIData(utiData)
        XCTAssertNil(image, "Should skip non-Data values")
    }

    // MARK: - Full file: corrupt / non-plist file

    func testCorruptFile() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pictClipping")
        try! Data([0xFF, 0xFE, 0x00, 0x01]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNil(image, "Should return nil for non-plist files")
    }

    // MARK: - Full file: nonexistent file

    func testNonexistentFile() {
        let url = URL(fileURLWithPath: "/tmp/does-not-exist-\(UUID().uuidString).pictClipping")
        let image = PictClippingParser.image(from: url)
        XCTAssertNil(image, "Should return nil for missing files")
    }

    // MARK: - Full file: empty file

    func testEmptyFile() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pictClipping")
        try! Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNil(image, "Should return nil for empty files")
    }

    // MARK: - findTIFF: little-endian header

    func testFindTIFFLittleEndian() {
        // Prefix garbage + TIFF LE magic
        var data = Data([0x00, 0x00, 0x00, 0x00, 0x00])
        data.append(contentsOf: [0x49, 0x49, 0x2A, 0x00]) // II*\0
        data.append(contentsOf: [0xDE, 0xAD])

        let range = PictClippingParser.findTIFF(in: data)
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.lowerBound, 5, "Should find TIFF at offset 5")
        XCTAssertEqual(range?.upperBound, data.count)
    }

    // MARK: - findTIFF: big-endian header

    func testFindTIFFBigEndian() {
        var data = Data([0xFF, 0xFF])
        data.append(contentsOf: [0x4D, 0x4D, 0x00, 0x2A]) // MM\0*
        data.append(contentsOf: [0xBE, 0xEF])

        let range = PictClippingParser.findTIFF(in: data)
        XCTAssertNotNil(range)
        XCTAssertEqual(range?.lowerBound, 2)
    }

    // MARK: - findTIFF: no header present

    func testFindTIFFNotPresent() {
        let data = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05])
        let range = PictClippingParser.findTIFF(in: data)
        XCTAssertNil(range, "Should return nil when no TIFF magic is present")
    }

    // MARK: - findTIFF: data too short

    func testFindTIFFTooShort() {
        let data = Data([0x49, 0x49, 0x2A]) // 3 bytes, needs 4
        let range = PictClippingParser.findTIFF(in: data)
        XCTAssertNil(range, "Should return nil when data is shorter than TIFF header")
    }

    // MARK: - findTIFF: empty data

    func testFindTIFFEmpty() {
        let range = PictClippingParser.findTIFF(in: Data())
        XCTAssertNil(range)
    }

    // MARK: - Resource fork via xattr

    func testResourceForkWithTIFFXattr() {
        let tiff = makeTestTIFF()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pictClipping")
        // Write an empty plist (no UTI-Data) so data fork fails
        let emptyPlist: [String: Any] = ["empty": true]
        let plistData = try! PropertyListSerialization.data(
            fromPropertyList: emptyPlist, format: .binary, options: 0
        )
        try! plistData.write(to: url)
        // Set the resource fork xattr with raw TIFF data
        tiff.withUnsafeBytes { ptr in
            setxattr(url.path, "com.apple.ResourceFork", ptr.baseAddress, tiff.count, 0, 0)
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNotNil(image, "Should extract image from ResourceFork xattr containing TIFF")
    }

    // MARK: - Resource fork with TIFF embedded after garbage prefix

    func testResourceForkWithEmbeddedTIFF() {
        let tiff = makeTestTIFF()
        var xattrData = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) // garbage prefix
        xattrData.append(tiff)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pictClipping")
        let emptyPlist: [String: Any] = ["empty": true]
        let plistData = try! PropertyListSerialization.data(
            fromPropertyList: emptyPlist, format: .binary, options: 0
        )
        try! plistData.write(to: url)
        xattrData.withUnsafeBytes { ptr in
            setxattr(url.path, "com.apple.ResourceFork", ptr.baseAddress, xattrData.count, 0, 0)
        }
        defer { try? FileManager.default.removeItem(at: url) }

        let image = PictClippingParser.image(from: url)
        XCTAssertNotNil(image, "Should find TIFF embedded after garbage bytes in ResourceFork")
    }
}
