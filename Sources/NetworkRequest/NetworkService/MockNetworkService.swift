
import Foundation

/// Used for mocking out certain requests. If a request is not handled it will fail with RequestError.noResponse
open class MockNetworkService: NetworkService {


    private var requests: [String: Result<Any, RequestError>] = [:]
    private var dynamicRequests: [String: [(Any) -> RequestResult<Any>?]] = [:]

    public init() {
        
    }

    open func mock<R: Request>(request: R, result: RequestResult<R.ResponseType>) {
        requests[request.description] = result.map { $0 }
    }

    open func mock<R: Request>(requestType: R.Type, result: RequestResult<R.ResponseType>) {
        self.mock(requestType: requestType, { _ in result })
    }

    open func mock<R: Request>(requestType: R.Type = R.self, _ response: @escaping (R) -> RequestResult<R.ResponseType>?) {
        dynamicRequests[requestType.typeName, default: []].append( { request in
            response(request as! R)?.map { $0 }
        })
    }

    open func mock<R: Request>(request: R, data: Data, statusCode: Int = 200) {
        do {
            let value = try request.decodeResponse(data: data, statusCode: statusCode)
            requests[request.description] = .success(value)
        } catch {
            requests[request.description] = .failure(.decodingError(data, error))
        }
    }

    open func unmockAll() {
        requests.removeAll()
        dynamicRequests.removeAll()
    }

    @discardableResult
    open func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable? {
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

fileprivate extension Request {

    static var typeName: String { return String(describing: Self.self)}
}
