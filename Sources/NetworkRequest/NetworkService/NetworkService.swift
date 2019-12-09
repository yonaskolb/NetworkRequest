
import Foundation

public protocol NetworkService {
    @discardableResult
    func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable?

    @available(iOS 13.0, *)
    func startSocket<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable?
}

public protocol Cancellable {
    func cancel()
}

extension URLSessionDataTask: Cancellable {}
@available(iOS 13.0, *)
extension URLSessionWebSocketTask: Cancellable {}

public typealias RequestResult<T> = Result<T, RequestError>
