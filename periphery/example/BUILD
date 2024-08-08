load(
    "//periphery:periphery_report.bzl",
    "periphery_report",
)

periphery_report(
    name = "periphery_xcode_report",
    format = "xcode",
    periphery_tool = "@com_github_peripheryapp_periphery//:periphery_tool",
    deps = [
        "//periphery/example/src:ReportTest",
    ],
)
