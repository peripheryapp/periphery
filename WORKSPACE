load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "9919ed1d8dae509645bfd380537ae6501528d8de971caebed6d5185b9970dc4d",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/2.1.1/rules_swift.2.1.1.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

PERIPHERY_VERSION = "2.21.0"

http_archive(
    name = "com_github_peripheryapp_periphery",
    build_file_content = """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
name = "periphery_tool",
src = "periphery",
out = "periphery_tool-bazel",
visibility = ["//visibility:public"],
)
        """,
    sha256 = "7ea2b48e3444609c83dd642a8eeff7240316bf081d331e4ca91eeedb439c0668",
    type = "zip",
    url = "https://github.com/peripheryapp/periphery/releases/download/{version}/periphery-{version}.zip".format(version = PERIPHERY_VERSION),
)
