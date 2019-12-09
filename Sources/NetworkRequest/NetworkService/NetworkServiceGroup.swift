
import Foundation

/// Used for combining multiple network services. This is useful when mocking with MockNetworkService and then falling back to HTTPNetworkService.
/// If one of the services doesn't handle the request by returning ResponseError.noResponse, the next service will run
public class NetworkServiceGroup: NetworkService {
    @available(iOS 13.0, *)
    public func startSocket<R>(_ request: R, completion: @escaping (Result<R.ResponseType, RequestError>) -> Void) -> Cancellable? where R: Request {
        var serviceIndex = 0

        func startSocket() {
            let service = services[serviceIndex]
            var socket: Cancellable?
            socket = service.startSocket(request) { result in

                if case let .failure(error) = result,
                    case .noResponse = error {
                    if serviceIndex < self.services.count - 1 {
                        serviceIndex += 1
                        startSocket()
                    } else {
                        completion(result)
                    }
                } else {
                    completion(result)
                }
                socket?.cancel()
            }
        }
        if services.isEmpty {
            completion(.failure(.noResponse))
        } else {
            startSocket()
        }
        return nil
    }

    public let services: [NetworkService]

    public init(services: [NetworkService]) {
        self.services = services
    }

    public func makeRequest<R>(_ request: R, completion: @escaping (Result<R.ResponseType, RequestError>) -> Void) -> Cancellable? where R: Request {
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
