load("@bazel_skylib//lib:sets.bzl", "sets")
load("@rules_swift//swift:providers.bzl", "SwiftInfo")
load("@rules_apple//apple:providers.bzl", "AppleResourceInfo")

PeripheryInfo = provider(
    doc = "TODO",
    fields = {
        "indexstores": "TODO",
        "plists": "TODO",
        "xibs": "TODO",
        "xcdatamodels": "TODO",
        "xcmappingmodels": "TODO",
        "test_targets": "TODO",
    },
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

def _get_template_substitutions(*, periphery_binary, config_path, generic_project_config_path):
    """Returns the template substitutions for this executable."""
    subs = {
        "periphery_binary": periphery_binary,
        "config_path": config_path,
        "generic_project_config_path": generic_project_config_path,
    }
    return {"%(" + k + ")s": subs[k] for k in subs}

def _scan_inputs_aspect_impl(target, ctx):
    indexstores = []
    test_targets = []
    plists = []
    xibs = []
    xcdatamodels = []
    xcmappingmodels = []

    if not target.label.workspace_name: # Ignore external deps
        if SwiftInfo in target and hasattr(target[SwiftInfo], "direct_modules"):
            for module in target[SwiftInfo].direct_modules:
                if hasattr(module, "swift"):
                    if ctx.rule.attr.testonly:
                        test_targets.append(module.name)

                    if hasattr(module.swift, "indexstore") and module.swift.indexstore:
                        indexstores.append(module.swift.indexstore)

        if AppleResourceInfo in target:
            # Each attribute has the structure '[(parent, resource_swift_module, resource_depset)]'
            info = target[AppleResourceInfo]

            if hasattr(info, "infoplists"):
                plists.extend(info.infoplists[0][2].to_list())

            if hasattr(info, "xibs"):
                xibs.extend(info.xibs[0][2].to_list())

            if hasattr(info, "storyboards"):
                # Periphery uses the same parser for xibs and storyboards.
                xibs.extend(info.storyboards[0][2].to_list())

            if hasattr(info, "datamodels"):
                # 'datamodels' contains both .xcdatamodel and .xcmappingmodel files.
                # We separate them because Periphery uses a different parser for each.
                resources = info.datamodels[0][2].to_list()

                for resource in resources:
                    if ".xcdatamodel" in resource.path:
                        xcdatamodels.append(resource)
                    elif ".xcmappingmodel" in resource.path:
                        xcmappingmodels.append(resource)

    deps = getattr(ctx.rule.attr, "deps", [])

    indexstores_depset = depset(
        indexstores,
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
    xibs_depset = depset(
        direct = xibs,
        transitive = [dep[PeripheryInfo].xibs for dep in deps],
    )
    xcdatamodels_depset = depset(
        direct = xcdatamodels,
        transitive = [dep[PeripheryInfo].xcdatamodels for dep in deps],
    )
    xcmappingmodels_depset = depset(
        direct = xcmappingmodels,
        transitive = [dep[PeripheryInfo].xcmappingmodels for dep in deps],
    )

    return [
        PeripheryInfo(
            indexstores = indexstores_depset,
            plists = plists_depset,
            xibs = xibs_depset,
            xcdatamodels = xcdatamodels_depset,
            xcmappingmodels = xcmappingmodels_depset,
            test_targets = test_targets_depset,
        ),
    ]

def _scan_impl(ctx):
    indexstores_set = sets.make()
    plists_set = sets.make()
    xibs_set = sets.make()
    xcdatamodels_set = sets.make()
    xcmappingmodels_set = sets.make()
    test_targets_set = sets.make()

    for dep in ctx.attr.deps:
        indexstores_set = sets.union(indexstores_set, sets.make(dep[PeripheryInfo].indexstores.to_list()))
        plists_set = sets.union(plists_set, sets.make(dep[PeripheryInfo].plists.to_list()))
        xibs_set = sets.union(xibs_set, sets.make(dep[PeripheryInfo].xibs.to_list()))
        xcdatamodels_set = sets.union(xcdatamodels_set, sets.make(dep[PeripheryInfo].xcdatamodels.to_list()))
        xcmappingmodels_set = sets.union(xcmappingmodels_set, sets.make(dep[PeripheryInfo].xcmappingmodels.to_list()))
        test_targets_set = sets.union(test_targets_set, sets.make(dep[PeripheryInfo].test_targets.to_list()))

    indexstores = sets.to_list(indexstores_set)
    plists = sets.to_list(plists_set)
    xibs = sets.to_list(xibs_set)
    xcdatamodels = sets.to_list(xcdatamodels_set)
    xcmappingmodels = sets.to_list(xcmappingmodels_set)
    test_targets = sets.to_list(test_targets_set)

    generic_project_config_struct = struct(
        indexstores = [file.path for file in indexstores],
        plists = [file.path for file in plists],
        xibs = [file.path for file in xibs],
        xcdatamodels = [file.path for file in xcdatamodels],
        xcmappingmodels = [file.path for file in xcmappingmodels],
        test_targets = test_targets,
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
        files = indexstores + plists + xibs + xcdatamodels + xcmappingmodels,
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
        "deps": attr.label_list(
            cfg = _force_indexstore,
            mandatory = True,
            aspects = [scan_inputs_aspect]
        ),
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
