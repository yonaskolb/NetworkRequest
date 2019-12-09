
import Foundation

/// Used to send requests via URL session
public class HTTPNetworkService: NetworkService {
    /// Will be prepended to all request baseURLs and paths
    var baseURL: String?
    var urlSession: URLSession
    var completionQueue = DispatchQueue.main
    var headers: [String: String]

    public init(baseURL: String? = nil, headers: [String: String] = [:], urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.headers = headers
        self.urlSession = urlSession
    }

    func createURLRequest<R: Request>(for request: R) throws -> URLRequest {
        var urlRequest = try request.getURLRequest()
        if let baseURL = baseURL {
            guard let url = urlRequest.url, let fullURL = URL(string: baseURL + url.absoluteString) else {
                fatalError("Invalid URL")
            }
            urlRequest.url = fullURL
        }

        for (name, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        return urlRequest
    }

    @discardableResult
    public func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable? {
        func complete(_ result: RequestResult<R.ResponseType>) {
            completionQueue.async {
                completion(result)
            }
        }

        let urlRequest: URLRequest
        do {
            urlRequest = try createURLRequest(for: request)
        } catch {
            complete(.failure(.encodingError(error)))
            return nil
        }

        let dataTask = urlSession.dataTask(with: urlRequest) { data, urlResponse, error in
            let result = self.handleResponse(request: request, data: data, urlResponse: urlResponse, error: error)
            complete(result)
        }

        dataTask.resume()
        return dataTask
    }

    @available(iOS 13.0, *)
    public func startSocket<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable? {
        func fail(_ error: RequestError) {
            complete(.failure(error))
        }

        func complete(_ result: RequestResult<R.ResponseType>) {
            completionQueue.async {
                completion(result)
            }
        }

        let urlRequest: URLRequest
        do {
            urlRequest = try createURLRequest(for: request)
        } catch {
            fail(.encodingError(error))
            return nil
        }

        let socketTask = urlSession.webSocketTask(with: urlRequest)
        socketTask.resume()

        func recieve() {
            socketTask.receive { result in

                switch result {
                case let .success(message):
                    switch message {
                    case let .data(data):
                        do {
                            let value = try request.decodeResponse(data: data, statusCode: 200)
                            complete(.success(value))
                        } catch {
                            fail(.decodingError(error))
                        }
                    case .string:
                        // not handled for now
                        break
                    @unknown default:
                        // not handled for now
                        break
                    }
                case let .failure(error):
                    fail(.networkError(error))
                }
                recieve()
            }
        }

        return socketTask
    }

    func handleResponse<R: Request>(request: R, data: Data?, urlResponse: URLResponse?, error: Error?) -> RequestResult<R.ResponseType> {
        if let error = error {
            return .failure(.networkError(error))
        } else if let data = data {
            let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
            if request.validStatusCode(statusCode) {
                do {
                    let value = try request.decodeResponse(data: data, statusCode: statusCode)
                    return .success(value)
                } catch {
                    return .failure(.decodingError(error))
                }
            } else {
                return .failure(.apiError(statusCode, data))
            }
        } else {
            return .failure(.noResponse)
        }
    }
}
