
import Foundation

public protocol RequestHandler {

    /// called when request is created
    func requestCreated(request: AnyRequest)

    /// validates and modifies the request. complete must be called with either .success or .fail
    func modifyRequest(request: AnyRequest, urlRequest: URLRequest, complete: @escaping (Result<URLRequest, Error>) -> Void)

    /// called before request is sent
    func requestSent(request: AnyRequest)

    /// called when the request completes
    func requestCompleted(request: AnyRequest, result: RequestResult<Any>)
}

public extension RequestHandler {

    func requestCreated(request: AnyRequest){}
    func modifyRequest(request: AnyRequest, urlRequest: URLRequest, complete: @escaping (Result<URLRequest, Error>) -> Void) {
        complete(.success(urlRequest))
    }
    func requestSent(request: AnyRequest) {}
    func requestCompleted(request: AnyRequest, result: RequestResult<Any>) {}
}

/// Group different RequestBehaviours together
public struct RequestHandlerGroup: RequestHandler {

    let handlers: [RequestHandler]

    public init(handlers: [RequestHandler]) {
        self.handlers = handlers
    }

    public func requestCreated(request: AnyRequest) {
        handlers.forEach {
            $0.requestCreated(request: request)
        }
    }

    public func requestSent(request: AnyRequest) {
        handlers.forEach {
            $0.requestSent(request: request)
        }
    }

    public func modifyRequest(request: AnyRequest, urlRequest: URLRequest, complete: @escaping (Result<URLRequest, Error>) -> Void) {
        if handlers.isEmpty {
            complete(.success(urlRequest))
            return
        }

        var count = 0
        var modifiedRequest = urlRequest
        func validateNext() {
            let handler = handlers[count]
            handler.modifyRequest(request: request, urlRequest: modifiedRequest) { result in
                count += 1
                switch result {
                case .success(let urlRequest):
                    modifiedRequest = urlRequest
                    if count == self.handlers.count {
                        complete(.success(modifiedRequest))
                    } else {
                        validateNext()
                    }
                case .failure(let error):
                    complete(.failure(error))
                }
            }
        }
        validateNext()
    }

    public func requestCompleted(request: AnyRequest, result: RequestResult<Any>) {
        handlers.forEach {
            $0.requestCompleted(request: request, result: result)
        }
    }
}

/// Wraps a RequestHandler in an easy to use struct that can be initialized with any request
public struct AnyRequestHandler {

    let request: AnyRequest
    let handler: RequestHandler

    public init<R: Request>(request: R, handler: RequestHandler) {
        self.request = AnyRequest(request)
        self.handler = handler
    }

    func requestCreated() {
        handler.requestCreated(request: request)
    }

    public func requestSent() {
        handler.requestSent(request: request)
    }

    public func modifyRequest(_ urlRequest: URLRequest, complete: @escaping (Result<URLRequest, Error>) -> Void) {
        handler.modifyRequest(request: request, urlRequest: urlRequest, complete: complete)
    }

    public func requestCompleted(result: RequestResult<Any>) {
        handler.requestCompleted(request: request, result: result)
    }
}

public struct AnyRequest: Request {

    public typealias ResponseType = Any
    public var path: String
    public var baseURL: String
    public var method: HTTPMethod
    public var headers: [String: String]
    public var urlParams: [String: Any?]
    public var requestName: String
    public var validStatusCode: (Int) -> Bool
    public var decodeResponse: (Data, Int) throws -> ResponseType
    public var encodeBody: () throws -> Data?
    public var getURLRequest: () throws -> URLRequest

    init<R: Request>(_ request: R) {
        self.path = request.path
        self.baseURL = request.baseURL
        self.method = request.method
        self.headers = request.headers
        self.urlParams = request.urlParams
        self.requestName = request.requestName
        self.validStatusCode = request.validStatusCode
        self.decodeResponse = request.decodeResponse
        self.encodeBody = request.encodeBody
        self.getURLRequest = request.getURLRequest
    }

    public func decodeResponse(data: Data, statusCode: Int) throws -> Any {
        try self.decodeResponse(data, statusCode)
    }

}
