RELEASE_BUILD_FLAGS=-c release --disable-sandbox
RELEASE_EXECUTABLE=$(shell swift build $(RELEASE_BUILD_FLAGS) --show-bin-path)/periphery

.PHONY: all $(MAKECMDGOALS)

all: build

build:
	@swift build

build_release:
	@swift build $(RELEASE_BUILD_FLAGS)

proj: build
	@rm -rf Periphery.xcodeproj
	@swift package generate-xcodeproj
	@cp Tests/Configs/*.xcscheme Periphery.xcodeproj/xcshareddata/xcschemes/
	@open Periphery.xcodeproj

lint:
	@swiftlint lint --quiet

test:
	@set -o pipefail && swift test 2>&1 | bundle exec xcpretty -tc

install: build_release
	install -d "$(PREFIX)/bin/"
	install "$(RELEASE_EXECUTABLE)" "$(PREFIX)/bin/"
