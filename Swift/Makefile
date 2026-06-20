APP_NAME := AutoSend
APP_BUNDLE := $(APP_NAME).app
BUILD_DIR := $(shell swift build -c release --show-bin-path 2>/dev/null || echo .build/release)

.PHONY: build clean install run release

build:
	swift build -c release
	$(eval BUILD_DIR := $(shell swift build -c release --show-bin-path))
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp Resources/*.icns $(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true
	codesign --force --sign - $(APP_BUNDLE)
	@echo "\n✅ Built $(APP_BUNDLE)"

run: build
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

install: build
	rm -rf /Applications/$(APP_BUNDLE)
	ditto $(APP_BUNDLE) /Applications/$(APP_BUNDLE)
	@echo "✅ Installed to /Applications/$(APP_BUNDLE)"

release:
	cd .. && SIGNING_IDENTITY="$$SIGNING_IDENTITY" NOTARY_PROFILE="$$NOTARY_PROFILE" ./scripts/release_arm64.sh
