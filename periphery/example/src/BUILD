load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

swift_library(
    name = "ReportTest",
    srcs = [
        "periphery_test.swift",
    ],
    data = [
        "Info.plist",
    ],
    visibility = ["//periphery/example:__pkg__"],
)
