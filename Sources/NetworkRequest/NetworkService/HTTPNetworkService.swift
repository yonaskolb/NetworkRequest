
import Foundation

public class HTTPNetworkService: NetworkService {

    /// Will be prepended to all request baseURLs and paths
    let baseURL: String?
    let urlSession: URLSession
    let completionQueue = DispatchQueue.main

    public init(baseURL: String? = nil, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    @discardableResult
    public func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable? {

        func fail(_ error: RequestError) {
            complete(.failure(error))
        }

        func complete(_ result: RequestResult<R.ResponseType>) {
            completionQueue.async {
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
        let dataTask = urlSession.dataTask(with: urlRequest) { (data, urlResponse, error) in

            if let error = error {
                fail(.networkError(error))
            } else if let data = data {
                let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
                if request.validStatusCode(statusCode) {
                    do {
                        let value = try request.decodeResponse(data: data, statusCode: statusCode)
                        complete(.success(value))
                    } catch {
                        fail(.decodingError(error))
                    }
                } else {
                    fail(.apiError(statusCode, data))
                }
            } else {
                fail(.noResponse)
            }
        }

        dataTask.resume()
        return dataTask
    }
}
