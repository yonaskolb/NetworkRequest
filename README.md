# NetworkRequest

A simple networking library for easily defining, executing and mocking network requests.

```swift

struct GetPosts: JSONDecodableRequest {  
    let userId: Int

    typealias ResponseType = [Post]
    let path: String = "/posts"
    var urlParams: [String: Any?] { return ["userId": userId] }
}

struct Post: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

let networkService = HTTPNetworkService(baseURL: "https://jsonplaceholder.typicode.com")
let request = GetPosts(userId: 2)

networkService.makeRequest(request) { result in
    switch result {
    case .success(let posts): // posts is [Post]
        print(posts) 
    case .failure(let error): // error is RequestError
        print(error)
    }
}
```
