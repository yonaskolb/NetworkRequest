
import XCTest
import NetworkRequest

class NetworkGroupTests: XCTestCase {

    func testEmptyGroup() throws {
        let networkService = NetworkServiceGroup(services: [])
        assertNetworkResponse(service: networkService, request: ItemRequest(), expectedResult: .failure(.noResponse))
    }

    func testMultiGroup() throws {
        let mock1 = MockNetworkService()
        let mock2 = MockNetworkService()

        let request = ItemRequest()
        let item = Item(name: "test")
        mock2.mock(request: request, result: .success(item))

        var networkService: NetworkServiceGroup

        networkService  = NetworkServiceGroup(services: [mock1, mock2])
        assertNetworkResponse(service: networkService, request: request, expectedResult: .success(item))

        networkService = NetworkServiceGroup(services: [mock2, mock1])
        assertNetworkResponse(service: networkService, request: request, expectedResult: .success(item))
    }
}

fileprivate struct ItemRequest: JSONDecodableRequest {

    typealias ResponseType = Item
    var name: String? = nil
    let path: String = "/item"
}

fileprivate struct Item: Codable, Equatable {
    let name: String
}
