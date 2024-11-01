"""
    Internal module extensions.
"""

load(
    "//bazel/internal:repositories.bzl",
    "periphery_dependencies",
)

non_module_deps = module_extension(implementation = lambda _: periphery_dependencies())
