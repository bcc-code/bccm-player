
import Foundation

func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
    URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
}

func getData(from url: URL) async throws -> Data? {
    return try await withUnsafeThrowingContinuation { continuation in
        getData(from: url) { data, response, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: data)
            }
        }
    }
}
