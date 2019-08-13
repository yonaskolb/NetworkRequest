
import XCTest
import NetworkRequest

class HTTPNetworkRequest: XCTestCase {

    let networkService = HTTPNetworkService(baseURL: "https://jsonplaceholder.typicode.com")

    func testNetworkRequest() {

        let request = GetPosts(userId: 2)
        let expectation = XCTestExpectation()
        networkService.makeRequest(request) { result in
            switch result {
            case .success(let posts):
                _ = posts.count
            case .failure(let error):
                print(error)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testNetworkRequestEncoding() throws {

        let body = PostBody(userId: 4, title: "My title", body: "My body")
        let request = SavePost(body: body)

        let expectation = XCTestExpectation()
        networkService.makeRequest(request) { result in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }
}

fileprivate struct GetPosts: JSONDecodableRequest {
    typealias ResponseType = [Post]
    let userId: Int

    let path: String = "/posts"
    var urlParams: [String: Any?] { return ["userId": userId] }
}

fileprivate struct SavePost: Request, JSONEncodableRequest {

    var body: PostBody

    let method: HTTPMethod = .post
    let path: String = "/posts"
}

fileprivate struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

fileprivate struct PostBody: Codable {
    let userId: Int
    let title: String
    let body: String
}
