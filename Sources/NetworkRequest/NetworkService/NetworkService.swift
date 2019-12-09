
import Foundation

public protocol NetworkService {

    @discardableResult
    func makeRequest<R: Request>(_ request: R, completion: @escaping (RequestResult<R.ResponseType>) -> Void) -> Cancellable?
}

public protocol Cancellable {
    func cancel()
}

public class CancelBlock: Cancellable {

    let block: () -> Void

    public init(block: @escaping () -> Void) {
        self.block = block
    }

    public func cancel() {
        block()
    }
}

extension URLSessionDataTask: Cancellable {}

public typealias RequestResult<T> = Result<T, RequestError>
