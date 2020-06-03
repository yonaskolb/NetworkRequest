
import Foundation

public enum RequestError: Error {
    /// A general networking error
    case networkError(URLError, Data?, HTTPURLResponse?)

    /// The request returned a non success response
    case apiError(Data, HTTPURLResponse?)

    /// The response body failed decoding
    case decodingError(Data, Error)

    /// The request body failed encoding
    case encodingError(Error)

    /// A request handler failed the request
    case handlerError(Error)

    /// A generic error. Could theoritically be a network error if URLSession error is not a URLError, though that should never be the case
    case genericError(Error)

    /// No error or data was returned. Shouldn't happen under normal circumstances. Also used by mock service when no mock is provided
    case noResponse

    public var name: String {
        switch self {
        case .networkError: return "Network error"
        case .apiError: return "API Error"
        case .decodingError: return "Decoding Error"
        case .encodingError: return "Encoding Error"
        case .handlerError(let error): return "\(error)"
        case .genericError: return "Error"
        case .noResponse: return "No response"
        }
    }

    public var message: String {
        switch self {
        case let .networkError(error, _, _): return "\(error.localizedDescription)"
        case let .apiError(data, response):
            var error = "API returned \(response?.statusCode ?? 0)"
            if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                error += ":\n\(string)"
            }
            return error
        case let .decodingError(_, error):
            if let error = error as? DecodingError {
                return "\(error.description)"
            } else {
                return "\(error)"
            }
        case let .encodingError(error): return "\(error)"
        case .handlerError: return ""
        case .noResponse: return ""
        case .genericError: return ""
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
