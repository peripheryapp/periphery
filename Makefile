RELEASE_BUILD_FLAGS=-c release --disable-sandbox --arch x86_64 --arch arm64
BIN_PATH=$(shell swift build $(RELEASE_BUILD_FLAGS) --show-bin-path)/periphery

build_release:
	@swift build $(RELEASE_BUILD_FLAGS)
	@install_name_tool -add_rpath @loader_path ${BIN_PATH}

show_bin_path:
	@echo ${BIN_PATH}
