# PictClipping Viewer

A macOS app that opens `.pictClipping` files and lets you view and export the embedded images.

## What are pictClipping files?

When you drag an image from an app (e.g. Safari, GraphicConverter) to the Finder desktop, macOS creates a `.pictClipping` file. These files contain image data in TIFF and/or PICT format, but Finder doesn't preview them well. This app extracts and displays the image, and lets you export it to standard formats.

## Requirements

- macOS 14+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An Apple ID (free) signed into Xcode

## Build & Install

1. Clone the repo:

```bash
git clone https://github.com/demiurge28/pictclipping-quicklook.git
cd pictclipping-quicklook
```

2. Set your development team in `project.yml`. Find your team ID with:

```bash
security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject | grep -o 'OU=[^,]*' | cut -d= -f2
```

Replace the `DEVELOPMENT_TEAM` value in `project.yml` with your team ID.

3. Build and install:

```bash
make install
```

This generates the Xcode project, builds a Release binary, and copies `PictClippingViewer.app` to `/Applications`.

## Set as Default App

To open `.pictClipping` files with a double-click:

1. Right-click any `.pictClipping` file in Finder
2. Click **Get Info**
3. Under **Open With**, select **PictClippingViewer**
4. Click **Change All…** to apply to all `.pictClipping` files

Or from the terminal:

```bash
open -a PictClippingViewer /path/to/file.pictClipping
```

## Usage

Double-click a `.pictClipping` file (or drag it onto the app icon). The image opens in a resizable window.

**Export:** Click the export button (↑) in the toolbar to save as:
- PNG
- JPEG
- TIFF
- BMP
- GIF

## How it works

The app reads image data from `.pictClipping` files two ways:

1. **Data fork** (modern, ~2015+) — parses the binary plist and extracts image data from `UTI-Data`, preferring TIFF > PNG > JPEG > PICT.
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

The project also includes a Quick Look Preview Extension. macOS currently does not invoke third-party extensions for `.pictClipping` files because the system's built-in `Clippings.qlgenerator` claims this UTI. The extension is included for forward compatibility.

## License

MIT
