def _generated_repo_impl(repository_ctx):
    repository_ctx.file(
        "BUILD",
        content = """
package_group(
    name = "package_group",
    packages = ["//..."],
)
""",
    )

    # TODO: Scope by project?
    repository_ctx.symlink(
        "/var/tmp/periphery_bazel/BUILD",
        "rule/BUILD",
    )

generated_repo = repository_rule(
    implementation = _generated_repo_impl,
)

generated = module_extension(implementation = lambda _: generated_repo(name = "periphery_generated"))