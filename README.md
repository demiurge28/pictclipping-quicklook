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

## Verify Installation

Check that the plugin is installed:

```bash
ls ~/Library/QuickLook/PictClippingQL.qlgenerator
```

Check which generator handles `.pictClipping` files:

```bash
qlmanage -m | grep pictclipping
```

Test the preview directly:

```bash
qlmanage -p /path/to/some/file.pictClipping
```

## Troubleshooting

### System generator takes priority

macOS ships with a built-in `Clippings.qlgenerator` at `/System/Library/QuickLook/` that also handles `.pictClipping` files. System generators take priority over user-installed ones. If `qlmanage -m | grep pictclipping` shows only the system generator, your previews are coming from Apple's built-in plugin, not this one.

To force this plugin to take priority, install it system-wide (requires admin):

```bash
sudo cp -R ~/Library/QuickLook/PictClippingQL.qlgenerator /Library/QuickLook/
qlmanage -r
```

### Preview not showing after install

1. Reset the Quick Look cache and restart Finder:

```bash
qlmanage -r && qlmanage -r cache && killall Finder
```

2. If that doesn't help, log out and back in — macOS caches generator registrations per login session.

3. Verify the plugin binary is valid:

```bash
file ~/Library/QuickLook/PictClippingQL.qlgenerator/Contents/MacOS/PictClippingQL
```

This should show `Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit bundle x86_64] [arm64:Mach-O 64-bit bundle arm64]`.

### Quick Look shows a blank or generic icon

The `.pictClipping` file may not contain recognizable image data. Inspect its contents:

```bash
plutil -p /path/to/file.pictClipping
```

Look for a `UTI-Data` dictionary with keys like `public.tiff` or `public.png`. If the file only has a `com.apple.ResourceFork` xattr (older format), check that:

```bash
xattr -l /path/to/file.pictClipping
```

## Development

```bash
make build      # Compile the .qlgenerator bundle
make clean      # Remove build artifacts
make reset      # Reset Quick Look cache and restart Finder
```

## License

MIT
