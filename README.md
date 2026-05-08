# PictClipping Quick Look Extension

A macOS Quick Look extension that lets you preview `.pictClipping` files by selecting them in Finder and pressing Space.

## What are pictClipping files?

When you drag an image from an app (e.g. Safari, GraphicConverter) to the Finder, macOS creates a `.pictClipping` file containing the image data in TIFF and/or PICT format. macOS does not provide a built-in Quick Look preview for these files.

## Requirements

- macOS 12.0+
- Xcode Command Line Tools (`xcode-select --install`)

No Apple Developer account or code signing required.

## Build & Install

```bash
make install
```

This will:
1. Compile a universal (arm64 + x86_64) `.qlgenerator` bundle
2. Install it to `~/Library/QuickLook/`
3. Reset the Quick Look cache

## Uninstall

```bash
make uninstall
```

## Usage

Select any `.pictClipping` file in Finder and press Space.

## How it works

The extension reads image data from the `.pictClipping` file in two ways:

1. **Data fork** (modern, ~2015+): Parses the binary plist and extracts image data from the `UTI-Data` dictionary, preferring TIFF over PNG/JPEG/PICT.
2. **Resource fork** (legacy): Reads the `com.apple.ResourceFork` extended attribute and scans for embedded TIFF data.

## Development

```bash
make build      # Compile the .qlgenerator bundle
make clean      # Remove build artifacts
make reset      # Reset Quick Look cache and restart Finder
```
