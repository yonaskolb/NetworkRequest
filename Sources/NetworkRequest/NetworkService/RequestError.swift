
import Foundation

public enum RequestError: Error, CustomStringConvertible {
    /// a general networking error
    case networkError(Error)

    /// the request returned a non success response
    case apiError(Int, Data)

    /// the response body failed decoding
    case decodingError(Error)

    /// the request body failed encoding
    case encodingError(Error)

    /// No error or data was returned. Shouldn't happen under normal circumstances. Also used by mock service when no mock is provided
    case noResponse

    public var description: String {
        switch self {
        case let .networkError(error): return "Network error:\n\n\(error.localizedDescription)"
        case let .apiError(statusCode, data):
            var error = "API returned \(statusCode)"
            if let string = String(data: data, encoding: .utf8) {
                error += ":\n\(string)"
            }
            return error
        case let .decodingError(error): return "Decoding Error:\n\n\(error)"
        case let .encodingError(error): return "Encoding Error:\n\n\(error)"
        case .noResponse: return "No response"
        }
    }
}
