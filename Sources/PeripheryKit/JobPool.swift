import Foundation

final class JobPool<T> {
    func map<J>(_ jobs: [J], _ block: @escaping (J) throws -> T?) throws -> [T] {
        let resultQueue = DispatchQueue(label: "resultQueue")
        var result = [T?](repeating: nil, count: jobs.count)
        var error: Error?

        DispatchQueue.concurrentPerform(iterations: jobs.count) { idx in
            guard error == nil else { return }

            let job = jobs[idx]
            var jobResult: T?

            do {
                jobResult = try block(job)
            } catch let e {
                error = e
            }

            if error != nil { return }

            resultQueue.sync {
                result[idx] = jobResult
            }
        }

        if let error = error {
            throw error
        }

        return result.compactMap { $0 }
    }

    func forEach<J>(_ jobs: [J], _ block: @escaping (J) throws -> Void) throws {
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
