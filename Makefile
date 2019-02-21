BUILD_FLAGS=-Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
RELEASE_BUILD_FLAGS=$(BUILD_FLAGS) -c release -Xswiftc -static-stdlib --disable-sandbox
RELEASE_EXECUTABLE=$(shell swift build $(RELEASE_BUILD_FLAGS) --show-bin-path)/periphery

.PHONY: all $(MAKECMDGOALS)

all: build

build:
	@swift build $(BUILD_FLAGS)

build_release:
	@swift build $(RELEASE_BUILD_FLAGS)

proj: build
	@rm -rf Periphery.xcodeproj
	@swift package generate-xcodeproj --xcconfig-overrides Sources/Configs/Periphery.xcconfig
	@cp Tests/Configs/RetentionFixtures.xcscheme Periphery.xcodeproj/xcshareddata/xcschemes/
	@open Periphery.xcodeproj

lint:
	@swiftlint lint --quiet

test:
	@set -o pipefail && swift test $(BUILD_FLAGS) 2>&1 | bundle exec xcpretty -tc

install: build_release
	install -d "$(PREFIX)/bin/"
	install "$(RELEASE_EXECUTABLE)" "$(PREFIX)/bin/"
