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

        assertNetworkResponse(service: networkService, request: request, expectedResult: .success(item))
        assertNetworkResponse(service: networkService, request: ItemRequest2(), expectedResult: .failure(.noResponse))
    }

    func testSuccessMock() throws {

        let request = ItemRequest()
        let item = Item(name: "test")
        networkService.mock(request: request, result: .success(item))

        assertNetworkResponse(service: networkService, request: request, expectedResult: .success(item))
        assertNetworkResponse(service: networkService, request: ItemRequest2(), expectedResult: .failure(.noResponse))
    }

    func testFailureMock() throws {

        let request = ItemRequest()
        networkService.mock(request: request, result: .failure(.apiError(500, Data("test".utf8))))
        
        assertNetworkResponse(service: networkService, request: request, expectedResult: .failure(.apiError(500, Data("test".utf8))))
        assertNetworkResponse(service: networkService, request: ItemRequest2(), expectedResult: .failure(.noResponse))
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

        assertNetworkResponse(service: networkService, request: ItemRequest(name: "test"), expectedResult: .success(item))
        assertNetworkResponse(service: networkService, request: ItemRequest(name: "invalid"), expectedResult: .failure(.noResponse))
        assertNetworkResponse(service: networkService, request: ItemRequest2(name: "test"), expectedResult: .failure(.noResponse))
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
