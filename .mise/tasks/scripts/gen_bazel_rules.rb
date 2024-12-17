#!/usr/bin/env ruby

require 'json'

PRODUCTS = {
    "ArgumentParser" => "@swift_argument_parser",
    "SystemPackage" => "@swift-system",
    "SwiftIndexStore" => "@swift-indexstore",
    "FilenameMatcher" => "@swift-filename-matcher",
    "Yams" => "@yams",
    "SwiftParser" => "@swift-syntax",
    "SwiftSyntax" => "@swift-syntax",
    "XcodeProj" => "@xcodeproj",
    "AEXML" => "@aexml",
}

def parse_json
    JSON.parse(`swift package describe --type json`)
rescue JSON::ParserError => e
    puts "Error parsing JSON: #{e.message}"
    exit 1
end

def target_labels(targets)
    targets.each_with_object({}) do |target, labels|
        labels[target["name"]] = generate_label(target)
    end
end

def generate_label(target)
    "//Sources:#{target["name"]}"
end

def generate_sources(target)
    path = target["path"].split("/").last

    target["sources"].map do |source|
        "#{path}/#{source}"
    end
end

def generate_dependencies(target, target_labels)
    deps = (target["target_dependencies"] || []).map { |dep| "\"#{target_labels[dep]}\"" }
    deps += (target["product_dependencies"] || []).map do |dep|
        pkg = PRODUCTS[dep]
        "\"#{pkg}//:#{dep}\""
    end
    deps
end

def generate_attrs(target, name, path, sources, deps)
    attrs = {
        "name" => "\"#{name}\"",
        "module_name" => "\"#{name}\"",
        "srcs" => sources.map { |src| src }
    }

    if target["type"] == "library"
    end

    attrs["deps"] = "[\n        #{deps.sort.join(",\n        ")}\n    ]" unless deps.empty?
    attrs
end

def generate_bazel_rule(path, rule, name, attrs)
    formatted_attrs = attrs.map { |k, v| "    #{k} = #{v}" }.join(",\n")
    formatted_rule = "#{rule}(\n#{formatted_attrs}\n)"

    if rule == "swift_binary"
        return <<~EOS
        #{formatted_rule}

        optimized_swift_binary(
            name = "#{name}_opt",
            target = ":#{name}",
            visibility = ["//:__pkg__"],
        )
        EOS
    else
        return formatted_rule
    end
end

json = parse_json
labels = target_labels(json["targets"])

rules = json["targets"].map do |target|
    name = target["name"]
    path = target["path"]

    next if path.start_with?("Tests")

    puts generate_label(target)

    type = target["type"]
    sources = generate_sources(target)
    deps = generate_dependencies(target, labels)

    rule = case type
            when "executable" then "swift_binary"
            when "test" then "swift_test"
            else "swift_library"
            end

    attrs = generate_attrs(target, name, path, sources, deps)
    generate_bazel_rule(path, rule, name, attrs)
end

File.write("Sources/BUILD.bazel", <<~EOS)
    load("@rules_swift//swift:swift.bzl", "swift_binary", "swift_library")
    load("//bazel/internal:opt.bzl", "optimized_swift_binary")  # buildifier: disable=bzl-visibility

    #{rules.join("\n\n")}
EOS

puts
exec("bazel", "run", "//bazel/dev:buildifier.fix")
