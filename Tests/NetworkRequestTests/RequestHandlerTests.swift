
import XCTest
import NetworkRequest

class RequestHandlerTests: XCTestCase {

    let networkService = HTTPNetworkService(baseURL: "https://jsonplaceholder.typicode.com")

    func testHandler() throws {

        let handler = MockHandler { urlRequest in
            var urlRequest = urlRequest
            urlRequest.addValue("1", forHTTPHeaderField: "one")
            return .success(urlRequest)
        }

        let networkService = HTTPNetworkService(baseURL: "https://jsonplaceholder.typicode.com", requestHandlers: [handler])

        let expectation = XCTestExpectation()
        let request = GetPosts(userId: 1)
        networkService.makeRequest(request) { result in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(handler.beforeSentCalled)

        let modified = try XCTUnwrap(handler.modified)
        let urlRequest = try modified.get()
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["one": "1"])

        let completed = try XCTUnwrap(handler.completed)
        let result = try completed.get()
        _ = try XCTUnwrap(result as? [Post])
    }

    func testHandlerGroup() throws {

        let handler1 = MockHandler { urlRequest in
            var urlRequest = urlRequest
            urlRequest.addValue("1", forHTTPHeaderField: "one")
            return .success(urlRequest)
        }

        let handler2 = MockHandler { urlRequest in
            var urlRequest = urlRequest
            urlRequest.addValue("2", forHTTPHeaderField: "two")
            return .success(urlRequest)
        }

        let group = RequestHandlerGroup(handlers: [handler1, handler2])
        let request = GetPosts(userId: 1)
        let requestHandler = AnyRequestHandler(request: request, handler: group)

        requestHandler.requestSent()
        requestHandler.requestCompleted(result: .success(2))
        var urlRequest: URLRequest?
        requestHandler.modifyRequest(try request.getURLRequest()) { result in
            urlRequest = try! result.get()
        }

        XCTAssertTrue(handler1.beforeSentCalled)
        XCTAssertTrue(handler2.beforeSentCalled)
        XCTAssertNotNil(try handler1.completed?.get())
        XCTAssertNotNil(try handler1.completed?.get())
        XCTAssertNotNil(try handler1.modified?.get())
        XCTAssertNotNil(try handler2.modified?.get())

        XCTAssertEqual(urlRequest?.allHTTPHeaderFields, ["one": "1", "two": "2"])
    }

    func testHandlerGroupFailure() throws {

        let modifiedError = StringError(string: "failed")
        let handler1 = MockHandler { urlRequest in
            .failure(modifiedError)
        }

        let handler2 = MockHandler { urlRequest in
            var urlRequest = urlRequest
            urlRequest.addValue("2", forHTTPHeaderField: "two")
            return .success(urlRequest)
        }

        let group = RequestHandlerGroup(handlers: [handler1, handler2])
        let request = GetPosts(userId: 1)
        let requestHandler = AnyRequestHandler(request: request, handler: group)

        requestHandler.requestCompleted(result: .failure(.handlerError(modifiedError)))
        var errorString: String?
        requestHandler.modifyRequest(try request.getURLRequest()) { result in
            if case .failure(let error) = result {
                errorString = String(describing: error)
            }
        }

        XCTAssertFalse(handler1.beforeSentCalled)
        XCTAssertFalse(handler2.beforeSentCalled)
        XCTAssertThrowsError(try handler1.modified?.get())
        XCTAssertNil(handler2.modified)
        XCTAssertThrowsError(try handler1.completed?.get())
        XCTAssertThrowsError(try handler1.completed?.get())

        XCTAssertEqual(errorString, "failed")
    }

    func testHandlerFailure() throws {

        let modifiedError = StringError(string: "failed")
        let handler1 = MockHandler { urlRequest in
            .failure(modifiedError)
        }

        let handler2 = MockHandler { urlRequest in
            var urlRequest = urlRequest
            urlRequest.addValue("2", forHTTPHeaderField: "two")
            return .success(urlRequest)
        }

        let networkService = HTTPNetworkService(baseURL: "https://jsonplaceholder.typicode.com", requestHandlers: [handler1, handler2])

        let expectation = XCTestExpectation()
        let request = GetPosts(userId: 1)
        var requestResult: RequestResult<[Post]>!
        networkService.makeRequest(request) { result in
            requestResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)

        switch requestResult {
        case .success:
            XCTFail("Should have failed")
        case .failure(let error):
            XCTAssertEqual(error.description, "failed")
        case .none:
            XCTFail("Should have been set")
        }
    }
}

class MockHandler: RequestHandler {

    let modifier: (URLRequest) -> Result<URLRequest, Error>

    var modified: Result<URLRequest, Error>?
    var beforeSentCalled: Bool = false
    var completed: RequestResult<Any>?

    init(modifier: @escaping (URLRequest) -> Result<URLRequest, Error>) {
        self.modifier = modifier
    }

    func modifyRequest(request: AnyRequest, urlRequest: URLRequest, complete: @escaping (Result<URLRequest, Error>) -> Void) {
        let result = modifier(urlRequest)
        modified = result
        complete(result)
    }
    func requestSent(request: AnyRequest) {
        beforeSentCalled = true
    }

    func requestCompleted(request: AnyRequest, result: RequestResult<Any>) {
        completed = result
    }
}

fileprivate struct StringError: Error, CustomStringConvertible {
    let string: String

    var description: String { string }
}

fileprivate struct GetPosts: JSONDecodableRequest {
    typealias ResponseType = [Post]
    let userId: Int

    let path: String = "/posts"
    var urlParams: [String: Any?] { return ["userId": userId] }
}

fileprivate struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
