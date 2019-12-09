
import Foundation

/// Used for mocking out certain requests. If a request is not handled it will fail with RequestError.noResponse
open class MockNetworkService: NetworkService {
    private var requests: [String: Result<Any, RequestError>] = [:]
    private var dynamicRequests: [String: [(Any) -> RequestResult<Any>?]] = [:]

    public init() {}

    public func mock<R: Request>(request: R, result: RequestResult<R.ResponseType>) {
        requests[request.description] = result.map { $0 }
    }

    public func mock<R: Request>(requestType: R.Type, result: RequestResult<R.ResponseType>) {
        mock(requestType: requestType) { _ in result }
    }

    public func mock<R: Request>(requestType: R.Type = R.self, _ response: @escaping (R) -> RequestResult<R.ResponseType>?) {
        dynamicRequests[requestType.typeName, default: []].append { request in
            response(request as! R)?.map { $0 }
        }
    }

    public func mock<R: Request>(request: R, data: Data, statusCode: Int = 200) {
        do {
            let value = try request.decodeResponse(data: data, statusCode: statusCode)
            requests[request.description] = .success(value)
        } catch {
            requests[request.description] = .failure(.decodingError(error))
        }
    }

    public func unmockAll() {
        requests.removeAll()
        dynamicRequests.removeAll()
    }

    @discardableResult
    public func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable? {
        if let requestResult = requests[request.description] {
            let result = requestResult.map { $0 as! R.ResponseType }
            completion(result)
            return nil
        }

        if let dynamicRequests = dynamicRequests[R.typeName] {
            for dynamicRequest in dynamicRequests {
                if let result = dynamicRequest(request) {
                    completion(result.map { $0 as! R.ResponseType })
                    return nil
                }
            }
        }

        completion(.failure(.noResponse))
        return nil
    }

    public func startSocket<R>(_ request: R, completion: @escaping (Result<R.ResponseType, RequestError>) -> Void) -> Cancellable? where R: Request {
        if let requestResult = requests[request.description] {
            let result = requestResult.map { $0 as! R.ResponseType }
            completion(result)
            return nil
        }

        if let dynamicRequests = dynamicRequests[R.typeName] {
            for dynamicRequest in dynamicRequests {
                if let result = dynamicRequest(request) {
                    completion(result.map { $0 as! R.ResponseType })
                    return nil
                }
            }
        }

        completion(.failure(.noResponse))
        return nil
    }
}

private extension Request {
    static var typeName: String { return String(describing: Self.self) }
}
