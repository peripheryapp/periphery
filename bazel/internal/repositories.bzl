"""
    Non-module dependencies that are not available in the Bazel ecosystem.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def periphery_dependencies():
    http_archive(
        name = "com_github_tuist_xcodeproj",
        build_file_content = """\
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "XcodeProj",
    srcs = glob(["Sources/XcodeProj/**/*.swift"]),
    visibility = ["//visibility:public"],
    deps = [
        "@aexml//:AEXML",
        "@com_github_kylef_pathkit//:PathKit",
    ],
)
    """,
        sha256 = "3990868f731888edabcaeacf639f0ee75e2e4430102a4f4bf40b03a60eeafe12",
        strip_prefix = "XcodeProj-8.24.7",
        url = "https://github.com/tuist/XcodeProj/archive/refs/tags/8.24.7.tar.gz",
    )

    http_archive(
        name = "com_github_kylef_pathkit",
        build_file_content = """\
load("@rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "PathKit",
    srcs = glob(["Sources/**/*.swift"]),
    visibility = ["//visibility:public"],
)
    """,
        sha256 = "fcda78cdf12c1c6430c67273333e060a9195951254230e524df77841a0235dae",
        strip_prefix = "PathKit-1.0.1",
        url = "https://github.com/kylef/PathKit/archive/refs/tags/1.0.1.tar.gz",
    )

    # TODO: https://github.com/apple/swift-system/pull/194
    http_archive(
        name = "com_github_apple_swift-system",
        build_file_content = """\
load("@rules_swift//swift:swift.bzl", "swift_library", "swift_test")

config_setting(
    name = "debug",
    values = {"compilation_mode": "dbg"},
)

cc_library(
    name = "CSystem",
    hdrs = glob(["Sources/CSystem/include/*.h"]),
    aspect_hints = ["@rules_swift//swift:auto_module"],
    defines = select({
        "@platforms//os:windows": ["_CRT_SECURE_NO_WARNINGS"],
        "//conditions:default": [],
    }),
    linkstatic = True,
    tags = ["swift_module=CSystem"],
)

DARWIN_DEFINES = ["SYSTEM_PACKAGE_DARWIN"]

swift_library(
    name = "SystemPackage",
    srcs = glob(["Sources/System/**/*.swift"]),
    defines = ["SYSTEM_PACKAGE"] +
            select({
                "@platforms//os:macos": DARWIN_DEFINES,
                "@platforms//os:ios": DARWIN_DEFINES,
                "@platforms//os:tvos": DARWIN_DEFINES,
                "@platforms//os:watchos": DARWIN_DEFINES,
                "@platforms//os:visionos": DARWIN_DEFINES,
                "//conditions:default": [],
            }) +
            select({
                ":debug": ["ENABLE_MOCKING"],
                "//conditions:default": [],
            }),
    module_name = "SystemPackage",
    visibility = ["//visibility:public"],
    deps = [":CSystem"],
)
    """,
        sha256 = "799474251c3654b5483c0f49045ff6729e07acebe9d1541aabfbec68d0390457",
        strip_prefix = "swift-system-1.4.0",
        url = "https://github.com/apple/swift-system/archive/refs/tags/1.4.0.tar.gz",
    )
