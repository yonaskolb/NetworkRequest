
import Foundation

/// Used to send requests via URL session
public class HTTPNetworkService: NetworkService {

    /// Will be prepended to all request baseURLs and paths
    var baseURL: String?
    var urlSession: URLSession
    var completionQueue = DispatchQueue.main
    var headers: [String: String]
    var requestHandlers: [RequestHandler]

    public init(baseURL: String? = nil, headers: [String: String] = [:], urlSession: URLSession = .shared, requestHandlers: [RequestHandler] = []) {
        self.baseURL = baseURL
        self.headers = headers
        self.urlSession = urlSession
        self.requestHandlers = requestHandlers
    }

    @discardableResult
    open func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable? {

        let id = UUID().uuidString
        let requestHandler = AnyRequestHandler(id: id, request: request, handler: RequestHandlerGroup(handlers: requestHandlers))
        requestHandler.requestCreated()

        func fail(_ error: RequestError) {
            complete(.failure(error))
        }

        func complete(_ result: RequestResult<R.ResponseType>) {
            completionQueue.async {
                requestHandler.requestCompleted(result: result.map { $0 })
                completion(result)
            }
        }

        var urlRequest: URLRequest
        do {
            urlRequest = try request.getURLRequest()
        } catch {
            fail(.encodingError(error))
            return nil
        }
        if let baseURL = baseURL {
            guard let url = urlRequest.url, let fullURL = URL(string: baseURL + url.absoluteString) else {
                fatalError("Invalid URL")
            }
            urlRequest.url = fullURL
        }

        for (name, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        var dataTask: URLSessionDataTask?

        let cancelBlock = CancelBlock {
            if let dataTask = dataTask {
                dataTask.cancel()
            }
        }
        requestHandler.modifyRequest(urlRequest) { result in

            switch result {
            case .success(let urlRequest):
                dataTask = self.urlSession.dataTask(with: urlRequest) { (data, urlResponse, error) in
                    requestHandler.requestResponded(data: data, urlResponse: urlResponse as? HTTPURLResponse, error: error)
                    if let error = error {
                        if let urlError = error as? URLError {
                            fail(.networkError(urlError, data, urlResponse as? HTTPURLResponse))
                        } else {
                            fail(.genericError(error))
                        }
                    } else if let data = data {
                        let response = urlResponse as? HTTPURLResponse
                        let statusCode = response?.statusCode ?? 0
                        if request.validStatusCode(statusCode) {
                            do {
                                let value = try request.decodeResponse(data: data, statusCode: statusCode)
                                complete(.success(value))
                            } catch {
                                fail(.decodingError(data, error))
                            }
                        } else {
                            fail(.apiError(data, response))
                        }
                    } else {
                        fail(.noResponse)
                    }
                }

                dataTask?.resume()
                requestHandler.requestSent()
            case .failure(let error):
                fail(.handlerError(error))
            }
        }
        return cancelBlock
    }
}
