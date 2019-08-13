
import Foundation

public protocol EncodableRequest: Request {

    associatedtype BodyType: Encodable
    var encoder: Encoder { get }
    var body: BodyType { get }
}

public extension EncodableRequest {

    func encodeBody() throws -> Data? {
        return try encoder.encode(body)
    }
}

public protocol JSONEncodableRequest: EncodableRequest { }

public extension JSONEncodableRequest {

    var encoder: Encoder { return JSONEncoder() }
}

public protocol Encoder {

    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: Encoder {}
