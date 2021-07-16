RELEASE_BUILD_FLAGS=-c release --disable-sandbox --arch x86_64 --arch arm64
BIN_PATH=$(shell swift build $(RELEASE_BUILD_FLAGS) --show-bin-path)
XCODE_PATH:=$(shell xcode-select -p)

build_release:
	@swift build $(RELEASE_BUILD_FLAGS)
	@install_name_tool -add_rpath @loader_path ${BIN_PATH}/periphery

show_bin_path:
	@echo ${BIN_PATH}

uninstall:
	@rm -f "/usr/local/bin/periphery"

install: uninstall build_release
	@cp $(XCODE_PATH)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx/lib_InternalSwiftSyntaxParser.dylib $(BIN_PATH)
	@install_name_tool -change @executable_path/lib_InternalSwiftSyntaxParser.dylib @executable_path/../libexec/lib_InternalSwiftSyntaxParser.dylib $(BIN_PATH)/periphery
	@ln -s ${BIN_PATH}/periphery /usr/local/bin

