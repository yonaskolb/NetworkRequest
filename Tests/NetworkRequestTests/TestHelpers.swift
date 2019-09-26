import XCTest
import NetworkRequest

func assertNetworkResponse<R: Request>(service: NetworkService, request: R, expectedResult: RequestResult<R.ResponseType>, file: StaticString = #file, line: UInt = #line) where R.ResponseType: Equatable {

    var requestResult: RequestResult<R.ResponseType>!
    service.makeRequest(request) { result in
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
