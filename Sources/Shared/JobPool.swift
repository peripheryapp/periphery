import Foundation
import Synchronization

public struct JobPool<Job> {
    private let jobs: [Job]

    public init(jobs: [Job]) {
        self.jobs = jobs
    }

    public func forEach(_ block: @escaping (Job) throws -> Void) throws {
        var error: Error?

        DispatchQueue.concurrentPerform(iterations: jobs.count) { idx in
            guard error == nil else { return }

            do {
                let job = jobs[idx]
                try block(job)
            } catch let e {
                error = e
            }
        }

        if let error {
            throw error
        }
    }

    /// Throwing variant
    public func flatMap<Result>(_ block: @escaping (Job) throws -> [Result]) throws -> [Result] {
        var error: Error?
        let results = Mutex<[Result]>([])

        DispatchQueue.concurrentPerform(iterations: jobs.count) { idx in
            guard error == nil else { return }

            do {
                let job = jobs[idx]
                let result = try block(job)
                results.withLock { $0.append(contentsOf: result) }
            } catch let e {
                error = e
            }
        }

        if let error {
            throw error
        }

        return results.withLock { $0 }
    }

    /// Non-throwing variant
    public func flatMap<Result>(_ block: @escaping (Job) -> [Result]) -> [Result] {
        let results = Mutex<[Result]>([])

        DispatchQueue.concurrentPerform(iterations: jobs.count) { idx in
            let job = jobs[idx]
            let result = block(job)
            results.withLock { $0.append(contentsOf: result) }
        }

        return results.withLock { $0 }
    }
}
