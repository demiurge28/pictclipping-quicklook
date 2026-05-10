# PictClipping Viewer

A macOS app that opens `.pictClipping` files and lets you view and export the embedded images.

## What are pictClipping files?

When you drag an image from an app (e.g. Safari, GraphicConverter) to the Finder desktop, macOS creates a `.pictClipping` file. These files contain image data in TIFF and/or PICT format, but Finder doesn't preview them well. This app extracts and displays the image, and lets you export it to standard formats.

## Requirements

- macOS 14+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & Install

```bash
git clone https://github.com/demiurge28/pictclipping-quicklook.git
cd pictclipping-quicklook
make install
```

This generates the Xcode project, builds a Release binary, copies `PictClippingViewer.app` to `/Applications`, and registers the Quick Look extension.

No Apple Developer account is required — the app is ad-hoc signed to run locally.

## Usage

Right-click a `.pictClipping` file in Finder → **Open With** → **PictClippingViewer**. The image opens in a resizable window.

Or from the terminal:

```bash
open -a PictClippingViewer /path/to/file.pictClipping
```

> **Note:** Finder has a built-in handler for `.pictClipping` files that overrides the default app setting on double-click. Use right-click → Open With, drag onto the app icon, or the terminal command above.

**Export:** Click the export button (↑) in the toolbar to save as:
- PNG
- JPEG
- TIFF
- BMP
- GIF

## How it works

The app reads image data from `.pictClipping` files two ways:

1. **Data fork** (modern, ~2015+) — parses the binary plist and extracts image data from `UTI-Data`, preferring TIFF > PNG > JPEG > PDF > PICT. Vector formats (PDF, PICT) are rasterized to bitmaps for display.
2. **Resource fork** (legacy) — reads the `com.apple.ResourceFork` extended attribute and scans for embedded TIFF data.

## Uninstall

```bash
make uninstall
```

Or manually:

```bash
rm -rf /Applications/PictClippingViewer.app
```

## Development

```bash
make generate   # Generate .xcodeproj from project.yml
make build      # Generate + build
make clean      # Remove build artifacts and .xcodeproj
make reset      # Reset Quick Look cache and restart Finder
```

The project includes a Quick Look Preview Extension that provides native previews for `.pictClipping` files in Finder (press Space). After installing, enable the extension in **System Settings → Privacy & Security → Extensions → Quick Look**.

## License

MIT
