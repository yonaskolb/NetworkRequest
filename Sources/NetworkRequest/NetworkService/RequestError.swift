
import Foundation

public enum RequestError: Error {
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

    public var message: String {
        switch self {
        case let .networkError(error): return "\(error.localizedDescription)"
        case let .apiError(statusCode, data):
            var error = "API returned \(statusCode)"
            if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                error += ":\n\(string)"
            }
            return error
        case let .decodingError(error):
            if let error = error as? DecodingError {
                return "\(error.description)"
            } else {
                return "\(error)"
            }
        case let .encodingError(error): return "\(error)"
        case .noResponse: return ""
        }
    }

}

extension RequestError: LocalizedError {

    public var errorDescription: String? {
        message
    }
}

extension RequestError: CustomStringConvertible {
    public var description: String {
        var string = name
        if !message.isEmpty {
            string += "\n\(message)"
        }
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
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
            return "Key \"\(key.stringValue)\" not found\(codingPath)"
        case .typeMismatch(let type, _):
            return "Expected type \"\(type)\" not found\(codingPath)"
        case .dataCorrupted:
            return "\(contextDescription)\(codingPath)"
        case .valueNotFound(let type, _):
            return "Value \"\(type)\" not found\(codingPath)"
        default:
            return String(describing: self)
        }
    }

}
