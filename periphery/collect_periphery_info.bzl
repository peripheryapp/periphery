load("@build_bazel_rules_swift//swift:providers.bzl", "SwiftInfo")

PeripheryInfo = provider(
    doc = "Provides indexstore information for a target's recursive dependencies.",
    fields = {
        "periphery_file_target_mapping": "A File listing the sources of a target and paths to their respective indexstores.",
        "periphery_indexstore": "A File representing the indexstore of a target.",
        "srcs": "A list of sources for a target.",
    },
)

def _collect_periphery_info_aspect_imp(target, ctx):
    periphery_file_target_mapping = []
    periphery_indexstore = []
    srcs = []

    # Only act on SwiftInfo targets that are not testonly, and exist in the current workspace
    if SwiftInfo in target and not ctx.rule.attr.testonly and not target.label.workspace_name and hasattr(target[SwiftInfo], "direct_modules"):
        for module in target[SwiftInfo].direct_modules:
            if hasattr(module, "swift") and hasattr(module.swift, "indexstore") and module.swift.indexstore:
                periphery_file_target_mappings = ctx.actions.declare_file("{}_periphery_file_target_mappings.json".format(module.name))
                swift_srcs = [src for src in module.compilation_context.direct_sources if src.extension == "swift" and src.is_source]
                infoplist_srcs = [file for file in ctx.rule.files.data if file.extension == "plist"]
                ctx.actions.write(
                    output = periphery_file_target_mappings,
                    content = json.encode(_create_file_target_info(swift_srcs + infoplist_srcs, module.name)),
                )
                periphery_file_target_mapping.append(periphery_file_target_mappings)
                periphery_indexstore.append(module.swift.indexstore)
                srcs.extend(swift_srcs + infoplist_srcs)
    periphery_file_target_mapping_depset = depset(
        direct = periphery_file_target_mapping,
        transitive = [dep[PeripheryInfo].periphery_file_target_mapping for dep in ctx.rule.attr.deps] if hasattr(ctx.rule.attr, "deps") else [],
    )
    periphery_indexstore_depset = depset(
        direct = periphery_indexstore,
        transitive = [dep[PeripheryInfo].periphery_indexstore for dep in ctx.rule.attr.deps] if hasattr(ctx.rule.attr, "deps") else [],
    )
    srcs_depset = depset(
        direct = srcs,
        transitive = [dep[PeripheryInfo].srcs for dep in ctx.rule.attr.deps] if hasattr(ctx.rule.attr, "deps") else [],
    )
    return [
        PeripheryInfo(
            periphery_file_target_mapping = periphery_file_target_mapping_depset,
            periphery_indexstore = periphery_indexstore_depset,
            srcs = srcs_depset,
        ),
        OutputGroupInfo(
            periphery_file_target_mapping = periphery_file_target_mapping_depset,
            periphery_indexstore = periphery_indexstore_depset,
            srcs = srcs_depset,
        ),
    ]

def _create_file_target_info(srcs, module_name):
    info = {}
    for src in srcs:
        info[src.path] = [module_name]
    return {"file_targets": info}

collect_periphery_info_aspect = aspect(
    implementation = _collect_periphery_info_aspect_imp,
    attr_aspects = ["deps"],
)
