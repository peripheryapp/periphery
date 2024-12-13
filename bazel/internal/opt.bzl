"""
    Rules for enabling Swift optimizations.
"""

def _enable_optimizations_impl(
        settings,
        attr):  # @unused
    return {
        "//command_line_option:compilation_mode": "opt",
        "//command_line_option:features": settings["//command_line_option:features"] + [
            "swift.opt_uses_wmo",
            "-swift.opt_uses_osize",
        ],
    }

_enable_optimizations = transition(
    implementation = _enable_optimizations_impl,
    inputs = ["//command_line_option:features"],
    outputs = ["//command_line_option:compilation_mode", "//command_line_option:features"],
)

def _optimized_swift_binary_impl(ctx):
    default_info = ctx.attr.target[0][DefaultInfo]
    new_exe = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(
        output = new_exe,
        target_file = ctx.executable.target,
    )
    return [
        DefaultInfo(
            executable = new_exe,
            files = depset([new_exe], transitive = [default_info.files]),
            runfiles = ctx.runfiles().merge(default_info.default_runfiles),
        ),
    ]

optimized_swift_binary = rule(
    attrs = {
        "target": attr.label(
            cfg = _enable_optimizations,
            mandatory = True,
            executable = True,
        ),
    },
    executable = True,
    implementation = _optimized_swift_binary_impl,
)
