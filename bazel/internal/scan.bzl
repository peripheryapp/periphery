load("@bazel_skylib//lib:sets.bzl", "sets")
load("@rules_swift//swift:providers.bzl", "SwiftInfo")

PeripheryInfo = provider(
    doc = "TODO",
    fields = {
        "indexstores": "TODO",
        "test_targets": "TODO",
        "plists": "TODO"
    },
)

def _get_template_substitutions(*, periphery_binary, config_path, generic_project_config_path):
    """Returns the template substitutions for this executable."""
    subs = {
        "periphery_binary": periphery_binary,
        "config_path": config_path,
        "generic_project_config_path": generic_project_config_path,
    }
    return {"%(" + k + ")s": subs[k] for k in subs}

def _scan_inputs_aspect_impl(target, ctx):
    direct_indexstores = []
    test_targets = []
    plists = []

    if hasattr(ctx.rule.files, "data"):
        # TODO: Generated plists.
        plists.extend([file for file in ctx.rule.files.data if file.extension == "plist"])

    # and not target.label.workspace_name
    if SwiftInfo in target and hasattr(target[SwiftInfo], "direct_modules"):
        for module in target[SwiftInfo].direct_modules:
            if hasattr(module, "swift"):
                if ctx.rule.attr.testonly:
                    test_targets.append(module.name)

                if hasattr(module.swift, "indexstore") and module.swift.indexstore:
                    direct_indexstores.append(module.swift.indexstore)

    deps = getattr(ctx.rule.attr, "deps", [])

    indexstores_depset = depset(
        direct = direct_indexstores,
        transitive = [dep[PeripheryInfo].indexstores for dep in deps],
    )
    test_targets_depset = depset(
        direct = test_targets,
        transitive = [dep[PeripheryInfo].test_targets for dep in deps],
    )
    plists_depset = depset(
        direct = plists,
        transitive = [dep[PeripheryInfo].plists for dep in deps],
    )

    return [
        PeripheryInfo(
            indexstores = indexstores_depset,
            test_targets = test_targets_depset,
            plists = plists_depset
        ),
    ]

def _scan_impl(ctx):
    indexstores = sets.make()
    test_targets = sets.make()
    plists = sets.make()

    for dep in ctx.attr.deps:
        indexstores = sets.union(indexstores, sets.make(dep[PeripheryInfo].indexstores.to_list()))
        test_targets = sets.union(test_targets, sets.make(dep[PeripheryInfo].test_targets.to_list()))
        plists = sets.union(plists, sets.make(dep[PeripheryInfo].plists.to_list()))

    generic_project_config_struct = struct(
        indexstores = [store.path for store in sets.to_list(indexstores)],
        test_targets = sets.to_list(test_targets),
        plists = [plist.path for plist in sets.to_list(plists)],
    )

    generic_project_config_struct_json = json.encode_indent(generic_project_config_struct)
    generic_project_config_struct_file = ctx.actions.declare_file("generic_project_config.json")
    ctx.actions.write(generic_project_config_struct_file, generic_project_config_struct_json)

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.scan,
        substitutions = _get_template_substitutions(
            periphery_binary = ctx.attr.periphery_binary,
            config_path = ctx.attr.config,
            generic_project_config_path = generic_project_config_struct_file.path
        ),
    )

    runfiles = ctx.runfiles(
        files = [generic_project_config_struct_file],
    )

    return DefaultInfo(
        executable = ctx.outputs.scan,
        files = depset(
            [ctx.outputs.scan, generic_project_config_struct_file],
        ),
        runfiles = runfiles
    )

scan_inputs_aspect = aspect(
    _scan_inputs_aspect_impl,
    attr_aspects = ["deps"],
)

scan = rule(
    attrs = {
        "deps": attr.label_list(mandatory = True, aspects = [scan_inputs_aspect]),
        "config": attr.string(),
        "periphery_binary": attr.string(),
        "_template": attr.label(
            allow_single_file = True,
            default = "@periphery//bazel/internal:scan_template.sh",
        ),
    },
    outputs = {
        "generic_project_config": "generic_project_config.json",
        "scan": "scan.sh",
    },
    implementation = _scan_impl,
    executable = True,
)
