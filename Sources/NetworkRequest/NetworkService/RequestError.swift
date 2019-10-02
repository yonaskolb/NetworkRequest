
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

    public var name: String {
        switch self {
        case .networkError: return "Network error"
        case .apiError: return "API Error"
        case .decodingError: return "Decoding Error"
        case .encodingError: return "Encoding Error"
        case .noResponse: return "No response"
        }
    }

    public var description: String {
        switch self {
        case let .networkError(error): return "\(name):\n\(error.localizedDescription)"
        case let .apiError(statusCode, data):
            var error = "API returned \(statusCode)"
            if let string = String(data: data, encoding: .utf8) {
                error += ":\n\(string)"
            }
            return error
        case let .decodingError(error):
            if let error = error as? DecodingError {
                return "\(name): \(error.description)"
            } else {
                return "\(name):\n\(error)"
            }
        case let .encodingError(error): return "\(name):\n\(error)"
        case .noResponse: return name
        }
    }
}

private extension DecodingError {

    var context: DecodingError.Context? {
        switch self {

        case .typeMismatch(_, let context):
            return context
        case .valueNotFound(_, let context):
            return context
        case .keyNotFound(_, let context):
            return context
        case .dataCorrupted(let context):
            return context
        @unknown default:
            return nil
        }
    }

    var description: String {
        let codingPath: String
        let contextDescription: String
        if let context = context {
            codingPath = " at " + context.codingPath
            .map { $0.intValue.flatMap { "[\($0)]" } ?? $0.stringValue }
            .joined(separator: ".")
            .replacingOccurrences(of: ".[", with: "[")
            contextDescription = context.debugDescription
        } else {
            codingPath = ""
            contextDescription = ""
        }
        switch self {
        case .keyNotFound(let key, _):
            return "key \"\(key.stringValue)\" not found\(codingPath)"
        case .typeMismatch(let type, _):
            return "expected type \"\(type)\" not found\(codingPath)"
        case .dataCorrupted:
            return "data corrupted\(codingPath): \(contextDescription)"
        case .valueNotFound(let type, _):
            return "value \"\(type)\" not found\(codingPath)"
        default:
            return String(describing: self)
        }
    }

}
