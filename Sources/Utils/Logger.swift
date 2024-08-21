import Foundation
import BaseLogger
import Configuration

#if canImport(os)
    import os
#endif

public final class Logger {
    public static func configureBuffering() {
        var info = stat()
        fstat(STDOUT_FILENO, &info)

        if (info.st_mode & S_IFMT) == S_IFIFO {
            setlinebuf(stdout)
            setlinebuf(stderr)
        }
    }

    @usableFromInline let baseLogger: BaseLogger
    @usableFromInline let configuration: Configuration

    #if canImport(os)
        @usableFromInline let signposter = OSSignposter()
    #endif

    @inlinable
    public required init(baseLogger: BaseLogger = .shared, configuration: Configuration = .shared) {
        self.baseLogger = baseLogger
        self.configuration = configuration
    }

    @inlinable
    public func contextualized(with context: String) -> ContextualLogger {
        .init(logger: self, context: context)
    }

    @inlinable
    public func info(_ text: String, canQuiet: Bool = true) {
        guard !(configuration.quiet && canQuiet) else { return }
        baseLogger.info(text)
    }

    @inlinable
    public func debug(_ text: String) {
        guard configuration.verbose else { return }
        baseLogger.debug(text)
    }

    @inlinable
    public func warn(_ text: String, newlinePrefix: Bool = false) {
        guard !configuration.quiet else { return }
        baseLogger.warn(text, newlinePrefix: newlinePrefix)
    }

    @inlinable
    public func error(_ text: String) {
        baseLogger.error(text)
    }

    @inlinable
    public func beginInterval(_ name: StaticString) -> SignpostInterval {
        #if canImport(os)
            let id = signposter.makeSignpostID()
            let state = signposter.beginInterval(name, id: id)
            return .init(name: name, state: state)
        #else
            return SignpostInterval()
        #endif
    }

    @inlinable
    public func endInterval(_ interval: SignpostInterval) {
        #if canImport(os)
            signposter.endInterval(interval.name, interval.state)
        #endif
    }
}

public struct ContextualLogger {
    @usableFromInline let logger: Logger
    @usableFromInline let context: String

    @inlinable
    init(logger: Logger, context: String) {
        self.logger = logger
        self.context = context
    }

    @inlinable
    public func contextualized(with innerContext: String) -> ContextualLogger {
        logger.contextualized(with: "\(context):\(innerContext)")
    }

    @inlinable
    public func debug(_ text: String) {
        logger.debug("[\(context)] \(text)")
    }

    @inlinable
    public func beginInterval(_ name: StaticString) -> SignpostInterval {
        logger.beginInterval(name)
    }

    @inlinable
    public func endInterval(_ interval: SignpostInterval) {
        logger.endInterval(interval)
    }
}

#if canImport(os)
    public struct SignpostInterval {
        @usableFromInline let name: StaticString
        @usableFromInline let state: OSSignpostIntervalState

        @inlinable
        init(name: StaticString, state: OSSignpostIntervalState) {
            self.name = name
            self.state = state
        }
    }
#else
    public struct SignpostInterval {
        @usableFromInline
        init() {}
    }
#endif
