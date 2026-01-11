import Foundation
import SystemPackage

public enum CommentCommand: CustomStringConvertible, Hashable {
    public enum Override: CustomStringConvertible, Hashable {
        case location(FilePath, Int, Int)
        case kind(String)

        public var description: String {
            switch self {
            case let .location(path, line, column):
                "location=\"\(path.string):\(line):\(column)\""
            case let .kind(kind):
                "kind=\"\(kind)\""
            }
        }
    }

    case ignore
    case ignoreAll
    case ignoreParameters([String])
    case override([Override])

    public var description: String {
        switch self {
        case .ignore:
            return "ignore"
        case .ignoreAll:
            return "ignore:all"
        case let .ignoreParameters(params):
            let formattedParams = params.sorted().joined(separator: ",")
            return "ignore:parameters \(formattedParams)"
        case let .override(overrides):
            let formattedOverrides = overrides.map(\.description).joined(separator: " ")
            return "override \(formattedOverrides)"
        }
    }
}

public extension Sequence<CommentCommand> {
    var locationOverride: (FilePath, Int, Int)? {
        for command in self {
            switch command {
            case let .override(overrides):
                for override in overrides {
                    switch override {
                    case let .location(path, line, column):
                        return (path, line, column)
                    default:
                        break
                    }
                }
            default:
                break
            }
        }

        return nil
    }

    var kindOverride: String? {
        for command in self {
            switch command {
            case let .override(overrides):
                for override in overrides {
                    switch override {
                    case let .kind(kind):
                        return kind
                    default:
                        break
                    }
                }
            default:
                break
            }
        }

        return nil
    }

    var ignoredParameterNames: [String] {
        flatMap { command -> [String] in
            switch command {
            case let .ignoreParameters(params):
                params
            default:
                []
            }
        }
    }
}
