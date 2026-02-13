public enum CommandIgnoreKind {
    /// Ignored by a `// periphery:ignore` comment on the declaration itself,
    /// or by being a descendant/parameter of such a declaration.
    case declaration

    /// Ignored by a file-level `// periphery:ignore:all` comment.
    case file
}
