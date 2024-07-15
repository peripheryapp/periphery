import Foundation
import Shared

struct JobPool<T> {
    let jobs: [T]

    func forEach(_ block: @escaping (T) throws -> Void) throws {
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

        if let error = error {
            throw error
        }
    }

    func flatMap<R>(_ block: @escaping (T) throws -> [R]) throws -> [R] {
        var error: Error?
        var results: [R] = []
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

        if let error = error {
            throw error
        }

        return results
    }
}
