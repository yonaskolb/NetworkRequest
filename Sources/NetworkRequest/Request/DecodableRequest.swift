
import Foundation

public protocol DecodableRequest: Request {

    var decoder: Decoder { get }
}

public extension DecodableRequest where ResponseType: Decodable {

    func decodeResponse(data: Data, statusCode: Int) throws -> ResponseType {
        return try decoder.decode(ResponseType.self, from: data)
    }
}

public protocol JSONDecodableRequest: DecodableRequest { }

public extension JSONDecodableRequest {

    var decoder: Decoder { return JSONDecoder() }
}

public protocol Decoder {

    func decode<T: Decodable>(_ type: T.Type, from: Data) throws -> T
}

extension JSONDecoder: Decoder {}
