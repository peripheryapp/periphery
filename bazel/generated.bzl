"""
    Public generated repo extension.
"""

def _generated_repo_impl(repository_ctx):
    repository_ctx.symlink(
        "/var/tmp/periphery_bazel/BUILD.bazel",
        "BUILD.bazel",
    )

generated_repo = repository_rule(
    implementation = _generated_repo_impl,
)

generated = module_extension(implementation = lambda _: generated_repo(name = "periphery_generated"))
