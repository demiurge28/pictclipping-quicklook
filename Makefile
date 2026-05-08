.PHONY: build install uninstall reset clean

BUNDLE_NAME  := PictClippingQL.qlgenerator
BUILD_DIR    := build
BUNDLE       := $(BUILD_DIR)/$(BUNDLE_NAME)
EXEC_DIR     := $(BUNDLE)/Contents/MacOS
EXEC         := $(EXEC_DIR)/PictClippingQL
INSTALL_DIR  := $(HOME)/Library/QuickLook

SOURCES := src/main.c src/GeneratePreview.m
FRAMEWORKS := -framework Foundation -framework AppKit -framework QuickLook -framework CoreServices
CFLAGS := -O2 -fobjc-arc -mmacosx-version-min=12.0 -arch arm64 -arch x86_64

build:
	@mkdir -p $(EXEC_DIR)
	clang $(CFLAGS) $(FRAMEWORKS) -bundle -o $(EXEC) $(SOURCES)
	cp src/Info.plist $(BUNDLE)/Contents/Info.plist
	@echo "Built $(BUNDLE)"

install: build
	@mkdir -p $(INSTALL_DIR)
	rm -rf "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	cp -R $(BUNDLE) "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	qlmanage -r 2>/dev/null
	@echo ""
	@echo "Installed to $(INSTALL_DIR)/$(BUNDLE_NAME)"
	@echo "Quick Look cache reset. Select a .pictClipping file and press Space."

uninstall:
	rm -rf "$(INSTALL_DIR)/$(BUNDLE_NAME)"
	qlmanage -r 2>/dev/null
	@echo "Uninstalled."

reset:
	qlmanage -r 2>/dev/null
	killall Finder 2>/dev/null || true

clean:
	rm -rf $(BUILD_DIR)
