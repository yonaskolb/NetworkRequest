
import Foundation

public class NetworkServiceGroup: NetworkService {

    public let services: [NetworkService]

    public init(services: [NetworkService]) {
        self.services = services
    }

    public func makeRequest<R>(_ request: R, completion: @escaping (Result<R.ResponseType, RequestError>) -> Void) -> Cancellable? where R : Request {

        var serviceIndex = 0

        func makeServiceRequest() {
            let service = services[serviceIndex]
            service.makeRequest(request) { result in

                if case let .failure(error) = result,
                    case .noResponse = error {
                    if serviceIndex < self.services.count - 1 {
                        serviceIndex += 1
                        makeServiceRequest()
                    } else {
                        completion(result)
                    }
                } else {
                    completion(result)
                }
            }

        }
        if services.isEmpty {
            completion(.failure(.noResponse))
        } else {
            makeServiceRequest()
        }
        return nil
    }
}
