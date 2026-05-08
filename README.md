# PictClipping Quick Look

A macOS Quick Look plugin for `.pictClipping` files. Select one in Finder, press Space, and see the image.

## What are pictClipping files?

When you drag an image from an app (e.g. Safari, GraphicConverter) to the Finder desktop, macOS creates a `.pictClipping` file containing the image in TIFF and/or PICT format.

## Install

**Requirements:** macOS 12+ and Xcode Command Line Tools (`xcode-select --install`). No Apple Developer account needed.

### Option 1: One-liner

```bash
git clone https://github.com/demiurge28/pictclipping-quicklook.git && cd pictclipping-quicklook && ./install.sh
```

### Option 2: Manual

```bash
git clone https://github.com/demiurge28/pictclipping-quicklook.git
cd pictclipping-quicklook
make install
```

Both methods compile a universal binary (arm64 + x86_64), install the plugin to `~/Library/QuickLook/`, and reset the Quick Look cache.

## Uninstall

```bash
make uninstall
```

Or manually:

```bash
rm -rf ~/Library/QuickLook/PictClippingQL.qlgenerator && qlmanage -r
```

## Usage

Select any `.pictClipping` file in Finder and press Space.

## How it works

The plugin reads image data from `.pictClipping` files two ways:

1. **Data fork** (modern, ~2015+) — parses the binary plist and extracts image data from `UTI-Data`, preferring TIFF > PNG > JPEG > PICT.
2. **Resource fork** (legacy) — reads the `com.apple.ResourceFork` extended attribute and scans for embedded TIFF data.

Both previews (Space bar) and Finder thumbnails are generated.

## Development

```bash
make build      # Compile the .qlgenerator bundle
make clean      # Remove build artifacts
make reset      # Reset Quick Look cache and restart Finder
```

## License

MIT
