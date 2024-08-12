load(
    ":collect_periphery_info.bzl",
    "PeripheryInfo",
    "collect_periphery_info_aspect",
)

def _force_indexstore_impl(settings, _attr):
    return {
        "//command_line_option:features": settings["//command_line_option:features"] + [
            "swift.index_while_building",
        ],
    }

_force_indexstore = transition(
    implementation = _force_indexstore_impl,
    inputs = [
        "//command_line_option:features",
    ],
    outputs = [
        "//command_line_option:features",
    ],
)

PeripheryReportInfo = provider(
    doc = "Provides periphery report information for usage by other targets.",
    fields = {
        "report": "A File containing a periphery report.",
    },
)

def _periphery_report_impl(ctx):
    periphery_file_inputs = _collect_file_inputs(ctx)
    args = ctx.actions.args()
    args.add_all([
        "--format=%s" % ctx.attr.format,
        "--skip-build",
        "--relative-results",
        "--quiet",
    ] + ctx.attr.periphery_additonal_args)
    if ctx.attr.report_exclude_globs:
        args.add("--report-exclude")
        for glob in ctx.attr.report_exclude_globs:
            args.add(glob)
    config_file_output = ctx.actions.declare_file("periphery_config.yml")
    ctx.actions.write(
        output = config_file_output,
        content = """
file_targets_path:
- {file_targets_paths}
index_store_path:
- {index_store_paths}
""".format(
            file_targets_paths = "\n- ".join([f.path for f in periphery_file_inputs.periphery_file_target_mapping_files]),
            index_store_paths = "\n- ".join([f.path for f in periphery_file_inputs.periphery_indexstore_files]),
        ),
    )
    args.add_all(["--config", config_file_output.path])
    extension = ctx.attr.format if ctx.attr.format == "json" else "txt"
    output_file = ctx.actions.declare_file(ctx.label.name + "_periphery_report.%s" % extension)
    ctx.actions.run_shell(
        tools = [
            ctx.executable.periphery_tool,
            config_file_output,
        ] + periphery_file_inputs.runfiles.files.to_list(),
        arguments = [args],
        outputs = [output_file],
        command = "{executable} scan $@ > {output_path}".format(
            executable = ctx.executable.periphery_tool.path,
            output_path = output_file.path,
        ),
        mnemonic = "GeneratePeripheryReport",
    )
    return [
        DefaultInfo(
            files = depset([output_file]),
            runfiles = periphery_file_inputs.runfiles,
        ),
        PeripheryReportInfo(
            report = output_file,
        ),
    ]

def _collect_file_inputs(ctx):
    runfiles = ctx.runfiles(
        files = [
            ctx.executable.periphery_tool,
        ],
    )
    periphery_file_target_mapping_files = []
    periphery_indexstore_files = []
    srcs_files = []
    for dep in ctx.attr.deps:
        dep_runfiles = []
        periphery_file_target_mapping_runfiles = ctx.runfiles(transitive_files = dep[PeripheryInfo].periphery_file_target_mapping)
        periphery_file_target_mapping_files.extend(dep[PeripheryInfo].periphery_file_target_mapping.to_list())
        dep_runfiles.append(periphery_file_target_mapping_runfiles)
        periphery_indexstore_paths_depset = ctx.runfiles(transitive_files = dep[PeripheryInfo].periphery_indexstore)
        periphery_indexstore_files.extend(dep[PeripheryInfo].periphery_indexstore.to_list())
        dep_runfiles.append(periphery_indexstore_paths_depset)
        srcs_depset = ctx.runfiles(transitive_files = dep[PeripheryInfo].srcs)
        srcs_files.extend(dep[PeripheryInfo].srcs.to_list())
        dep_runfiles.append(srcs_depset)
        for dep_runfile in dep_runfiles:
            runfiles = runfiles.merge(dep_runfile)
    return struct(
        runfiles = runfiles,
        periphery_file_target_mapping_files = periphery_file_target_mapping_files,
        periphery_indexstore_files = periphery_indexstore_files,
        srcs_files = srcs_files,
    )

periphery_report = rule(
    implementation = _periphery_report_impl,
    doc = "Creates a periphery report for the given targets.",
    attrs = {
        "deps": attr.label_list(
            cfg = _force_indexstore,
            aspects = [collect_periphery_info_aspect],
            doc = "The targets to generate a periphery report from.",
        ),
        "report_exclude_globs": attr.string_list(
            default = [],
            doc = "A list of file globs to exclude from the report.",
        ),
        "periphery_additonal_args": attr.string_list(
            doc = "A list additional arguments to pass to the periperhy invocation.",
        ),
        "format": attr.string(
            default = "xcode",
            values = [
                "xcode",
                "json",
                "csv",
                "checkstyle",
                "codeclimate",
                "github-actions",
            ],
            doc = "The output format to use.",
        ),
        "periphery_tool": attr.label(
            doc = "The periphery tool to use.",
            executable = True,
            cfg = "exec",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
