import XCTest
import NetworkRequest

class MockNetworkTests: XCTestCase {

    let networkService = MockNetworkService()

    override func setUp() {
        networkService.unmockAll()
    }

    func testDataMock() throws {

        let request = ItemRequest()

        let item = Item(name: "hello")
        let jsonEncoder = JSONEncoder()
        let data = try jsonEncoder.encode(item)
        networkService.mock(request: request, data: data)

        assertNetworkResponse(request: request, expectedResult: .success(item))
        assertNetworkResponse(request: ItemRequest2(), expectedResult: .failure(.noResponse))
    }

    func testSuccessMock() throws {

        let request = ItemRequest()
        let item = Item(name: "test")
        networkService.mock(request: request, result: .success(item))

        assertNetworkResponse(request: request, expectedResult: .success(item))
        assertNetworkResponse(request: ItemRequest2(), expectedResult: .failure(.noResponse))
    }

    func testFailureMock() throws {

        let request = ItemRequest()
        networkService.mock(request: request, result: .failure(.apiError(500, Data("test".utf8))))
        
        assertNetworkResponse(request: request, expectedResult: .failure(.apiError(500, Data("test".utf8))))
        assertNetworkResponse(request: ItemRequest2(), expectedResult: .failure(.noResponse))
    }

    func testDynamicMock() throws {

        let item = Item(name: "test")
        networkService.mock { (request: ItemRequest) in
            if request.name == "test" {
                return .success(item)
            } else {
                return nil
            }
        }

        assertNetworkResponse(request: ItemRequest(name: "test"), expectedResult: .success(item))
        assertNetworkResponse(request: ItemRequest(name: "invalid"), expectedResult: .failure(.noResponse))
        assertNetworkResponse(request: ItemRequest2(name: "test"), expectedResult: .failure(.noResponse))
    }

    func assertNetworkResponse<R: Request>(request: R, expectedResult: RequestResult<R.ResponseType>, file: StaticString = #file, line: UInt = #line) where R.ResponseType: Equatable {

        var requestResult: RequestResult<R.ResponseType>!
        networkService.makeRequest(request) { result in
            requestResult = result
        }
        guard let result = requestResult else {
            XCTFail("Request didn't return", file: file, line: line)
            return
        }

        switch (result, expectedResult) {
        case  (.success(let value), .success(let expectedValue)):
            XCTAssertEqual(value, expectedValue, file: file, line: line)
        case (.failure(let error), .failure(let expectedError)):
            XCTAssertEqual(error.description, expectedError.description, file: file, line: line)
        default:
            XCTFail("Result didn't match. Recieved \(result) but expected \(expectedResult)", file: file, line: line)
        }

    }
}

fileprivate struct ItemRequest: JSONDecodableRequest {

    typealias ResponseType = Item
    var name: String? = nil
    let path: String = "/item"
}

fileprivate struct ItemRequest2: JSONDecodableRequest {

    typealias ResponseType = Item
    var name: String? = nil
    let path: String = "/item2"
}

fileprivate struct Item: Codable, Equatable {
    let name: String
}
