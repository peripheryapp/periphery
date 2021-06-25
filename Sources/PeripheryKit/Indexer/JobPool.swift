import Foundation

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
}
