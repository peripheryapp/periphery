import Foundation

public struct JobPool<Job> {
    let jobs: [Job]

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
        var results: [Result] = []
        let lock = UnfairLock()

        DispatchQueue.concurrentPerform(iterations: jobs.count) { idx in
            guard error == nil else { return }

            do {
                let job = jobs[idx]
                let result = try block(job)

                lock.perform {
                    results.append(contentsOf: result)
                }
            } catch let e {
                error = e
            }
        }

        if let error {
            throw error
        }

        return results
    }

    /// Non-throwing variant
    public func flatMap<Result>(_ block: @escaping (Job) -> [Result]) -> [Result] {
        var results: [Result] = []
        let lock = UnfairLock()

        DispatchQueue.concurrentPerform(iterations: jobs.count) { idx in
            let job = jobs[idx]
            let result = block(job)

            lock.perform {
                results.append(contentsOf: result)
            }
        }

        return results
    }
}
