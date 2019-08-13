
import Foundation

/**
 A protocol to conform to for specific network requests.
 Most properties have defaults you only have to provide the minimum information about a request
**/
public protocol Request: CustomStringConvertible {

    associatedtype ResponseType = Void

    /// the path of the request eg: /pets
    var path: String { get }

    /// defaults to an empty string.
    /// The baseURL from the HTTPNetworkService will also be prepended so that can be used if all the requests have the same baseURL
    var baseURL: String { get }

    /// defaults to .get
    var method: HTTPMethod { get }

    /// defaults to an empty dictionary
    var headers: [String: String] { get }

    /// defaults to an empty dictionary
    var urlParams: [String: Any?] { get }

    /// defaults to the object name
    var requestName: String { get }

    /**
     Whether a given status code is valid.
     If this returns false then a RequestError.invalidStatus code error will be returned.
     It can be used to return something like an enum with associated types for both success and failure responses
     This defaults to returning true for 2xx and 3xx responses.
     ***/
    func validStatusCode(_ statusCode: Int) -> Bool

    /// How to decode a given response from data. This is provided by default in DecodableRequest and JSONDecodableRequest
    func decodeResponse(data: Data, statusCode: Int) throws -> ResponseType

    /// How to encode a body. This returns nil by default which means no body will be sent
    func encodeBody() throws -> Data?

    /// get a fully formed URLRequest. This is provided by default and uses all of the above properties to create a URLRequest
    func getURLRequest() throws -> URLRequest
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public extension Request {

    var baseURL: String { return "" }
    var method: HTTPMethod { return .get }
    var headers: [String: String] { return [:] }
    var urlParams: [String: Any?] { return [:] }
    var requestName: String { return String(describing: Self.self)}

    func encodeBody() -> Data? { return nil }

    func validStatusCode(_ statusCode: Int) -> Bool {
        return statusCode.description.hasPrefix("2") || statusCode.description.hasPrefix("3")
    }

    func getURLRequest() throws -> URLRequest {
        let urlString = "\(baseURL)\(path)"
        guard var urlComponents = URLComponents(string: urlString) else {
            fatalError("Invalid url \(urlString)")
        }
        urlComponents.query = urlParams
            .compactMap { key, value -> (String, Any)? in
                guard let value = value else { return nil }
                return (key, value)
        }
        .map { "\($0)=\($1)" }
        .joined(separator: "&")
        guard let url = urlComponents.url else {
            fatalError("Invalid url \(urlComponents)")
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        if let body = try encodeBody() {
            urlRequest.httpBody = body
        }
        for (name, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        return urlRequest
    }

    var description: String {
        let params = self.urlParams
            .map { $0 }
            .sorted { $0.key < $1.key }
            .compactMap { param in
                if let value = param.value {
                    return "\(param.key): \(value)"
                } else {
                    return nil
                }
        }
        .joined(separator: ", ")
        return "\(requestName): \(method) \(path) \(params)"
    }
}

// provide empty decoding for no response
public extension Request where ResponseType == Void {

    func decodeResponse(data: Data, statusCode: Int) throws -> ResponseType {
        return ()
    }
}

// if response is a tuple with (Data, Int) the data and status code will be returned untouched
public extension Request where ResponseType == (Data, Int) {

    func decodeResponse(data: Data, statusCode: Int) throws -> ResponseType {
        return (data, statusCode)
    }
}
