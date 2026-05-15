"""
    Periphery public rules.
"""

load(
    "//bazel/internal/scan:scan.bzl",
    "periphery_deps_transition",
    "scan_impl",
    "scan_inputs_aspect",
    "scan_report_impl",
    "scan_test_impl",
)

_COMMON_ATTRS = {
    "deps": attr.label_list(
        cfg = periphery_deps_transition,
        mandatory = True,
        aspects = [scan_inputs_aspect],
        doc = "Top-level project targets to scan.",
    ),
    "config": attr.string(doc = "Path to the periphery.yml configuration file."),
    "global_indexstore": attr.string(doc = "Path to a global index store."),
    "periphery": attr.label(
        doc = "The periphery executable target.",
        default = "@periphery//:periphery",
    ),
}

scan = rule(
    doc = "Scans the top-level deps and their transitive deps for unused code.",
    attrs = dict(_COMMON_ATTRS, **{
        "_template": attr.label(
            allow_single_file = True,
            default = "@periphery//bazel/internal/scan:scan_template.sh",
        ),
    }),
    outputs = {
        "project_config": "%{name}_project_config.json",
        "scan": "%{name}.sh",
    },
    implementation = scan_impl,
    executable = True,
)

scan_test = rule(
    doc = """\
Scans the top-level deps and their transitive deps for unused code as a test target.

The test fails if Periphery reports any unused declarations (`--strict` is enabled).
Use this rule to wire Periphery into CI via `bazel test`.\
""",
    attrs = dict(_COMMON_ATTRS, **{
        "_template": attr.label(
            allow_single_file = True,
            default = "@periphery//bazel/internal/scan:scan_test_template.sh",
        ),
    }),
    outputs = {
        "project_config": "%{name}_project_config.json",
        "scan": "%{name}.sh",
    },
    implementation = scan_test_impl,
    test = True,
)

_REPORT_FORMATS = [
    "xcode",
    "csv",
    "json",
    "checkstyle",
    "codeclimate",
    "github-actions",
    "github-markdown",
    "gitlab-codequality",
]

scan_report = rule(
    doc = """\
Scans the top-level deps and their transitive deps for unused code and writes the
formatted report to a file output.

Unlike `scan` and `scan_test`, this rule runs Periphery at build time and exposes
the report as a regular Bazel file artifact, so it can be consumed by other rules
via `data` deps or `srcs`.\
""",
    attrs = dict(_COMMON_ATTRS, **{
        "format": attr.string(
            doc = "Output format for the report. One of: " + ", ".join(_REPORT_FORMATS) + ".",
            default = "json",
            values = _REPORT_FORMATS,
        ),
    }),
    outputs = {
        "report": "%{name}.report",
        "project_config": "%{name}_project_config.json",
    },
    implementation = scan_report_impl,
)
