import SystemPackage

/// The following is taken from PathKit by Kyle Fuller, with modifications for use with FilePath.
/// https://github.com/kylef/PathKit

#if os(Linux)
import Glibc

let system_glob = Glibc.glob
#else
import Darwin

let system_glob = Darwin.glob
#endif

public extension FilePath {
    static func glob(_ pattern: String) -> [Self] {
        var gt = glob_t()
        let cPattern = strdup(pattern)
        defer {
            globfree(&gt)
            free(cPattern)
        }

        let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
        if system_glob(cPattern, flags, nil, &gt) == 0 {
#if os(Linux)
            let matchc = gt.gl_pathc
#else
            let matchc = gt.gl_matchc
#endif
            return (0..<Int(matchc)).compactMap { index in
                if let path = String(validatingUTF8: gt.gl_pathv[index]!) {
                    return FilePath(path)
                }

                return nil
            }
        }

        // GLOB_NOMATCH
        return []
    }

    func glob(_ pattern: String) -> [FilePath] {
        return Self.glob((self.appending(pattern)).string)
    }
}
