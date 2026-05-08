# PictClipping Quick Look

A macOS Quick Look extension for `.pictClipping` files. Select one in Finder, press Space, and see the image.

## What are pictClipping files?

When you drag an image from an app (e.g. Safari, GraphicConverter) to the Finder desktop, macOS creates a `.pictClipping` file containing the image in TIFF and/or PICT format.

## Requirements

- macOS 14+
- Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An Apple ID (free) signed into Xcode for code signing

## Install

1. Set your `DEVELOPMENT_TEAM` in `project.yml` (find yours with `security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject | grep -o 'OU=[^,]*' | cut -d= -f2`)
2. Build and install:

```bash
git clone https://github.com/demiurge28/pictclipping-quicklook.git
cd pictclipping-quicklook
make install
```

3. Enable the extension in **System Settings → Privacy & Security → Extensions → Quick Look**

## Uninstall

```bash
make uninstall
```

## Usage

Select any `.pictClipping` file in Finder and press Space.

## How it works

The extension reads image data from `.pictClipping` files two ways:

1. **Data fork** (modern, ~2015+) — parses the binary plist and extracts image data from `UTI-Data`, preferring TIFF > PNG > JPEG > PICT.
2. **Resource fork** (legacy) — reads the `com.apple.ResourceFork` extended attribute and scans for embedded TIFF data.

## Verify Installation

Check the extension is registered:

```bash
pluginkit -m -p com.apple.quicklook.preview | grep pictclipping
```

## Troubleshooting

### Extension not showing in pluginkit

1. Launch the app once: `open /Applications/PictClippingViewer.app`
2. Reset Quick Look: `qlmanage -r && killall Finder`
3. Enable in **System Settings → Privacy & Security → Extensions → Quick Look**

### Preview not rendering

Inspect the `.pictClipping` file contents:

```bash
plutil -p /path/to/file.pictClipping
```

Look for a `UTI-Data` dictionary with keys like `public.tiff` or `public.png`.

## Development

```bash
make generate   # Generate .xcodeproj from project.yml
make build      # Generate + build
make clean      # Remove build artifacts and .xcodeproj
make reset      # Reset Quick Look cache and restart Finder
```

## License

MIT
