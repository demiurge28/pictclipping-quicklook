.PHONY: generate build test install uninstall reset clean

APP_NAME  := PictClippingViewer.app
BUILD_DIR := build

generate:
	xcodegen generate

build: generate
	xcodebuild -project PictClippingViewer.xcodeproj \
		-scheme PictClippingViewer \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build

test: generate
	xcodebuild -project PictClippingViewer.xcodeproj \
		-scheme PictClippingViewerTests \
		-derivedDataPath $(BUILD_DIR) \
		test

install: build
	rm -rf /Applications/$(APP_NAME)
	cp -R $(BUILD_DIR)/Build/Products/Release/$(APP_NAME) /Applications/
	qlmanage -r 2>/dev/null
	open /Applications/$(APP_NAME)
	@echo ""
	@echo "Installed to /Applications/$(APP_NAME)"
	@echo "Enable the extension in System Settings → Privacy & Security → Extensions → Quick Look."

uninstall:
	rm -rf /Applications/$(APP_NAME)
	qlmanage -r 2>/dev/null
	@echo "Uninstalled."

reset:
	qlmanage -r 2>/dev/null
	killall Finder 2>/dev/null || true

clean:
	rm -rf $(BUILD_DIR) PictClippingViewer.xcodeproj
