"""
    Periphery public rules.
"""

load("//bazel/internal/scan:scan.bzl", "force_indexstore", "scan_impl", "scan_inputs_aspect")

scan = rule(
    doc = "Scans the top-level deps and their transitive deps for unused code.",
    attrs = {
        "deps": attr.label_list(
            cfg = force_indexstore,
            mandatory = True,
            aspects = [scan_inputs_aspect],
            doc = "Top-level project targets to scan.",
        ),
        "config": attr.string(doc = "Path to the periphery.yml configuration file."),
        "periphery": attr.label(
            doc = "The periphery executable target.",
            default = "@periphery//:periphery",
        ),
        "_template": attr.label(
            allow_single_file = True,
            default = "@periphery//bazel/internal/scan:scan_template.sh",
        ),
    },
    outputs = {
        "project_config": "project_config.json",
        "scan": "scan.sh",
    },
    implementation = scan_impl,
    executable = True,
)
