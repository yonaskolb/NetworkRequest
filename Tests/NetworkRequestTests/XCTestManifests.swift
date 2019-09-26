#if !canImport(ObjectiveC)
import XCTest

extension HTTPNetworkRequest {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__HTTPNetworkRequest = [
        ("testNetworkRequest", testNetworkRequest),
        ("testNetworkRequestEncoding", testNetworkRequestEncoding),
    ]
}

extension MockNetworkTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MockNetworkTests = [
        ("testDataMock", testDataMock),
        ("testDynamicMock", testDynamicMock),
        ("testFailureMock", testFailureMock),
        ("testSuccessMock", testSuccessMock),
    ]
}

extension NetworkGroupTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__NetworkGroupTests = [
        ("testEmptyGroup", testEmptyGroup),
        ("testMultiGroup", testMultiGroup),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(HTTPNetworkRequest.__allTests__HTTPNetworkRequest),
        testCase(MockNetworkTests.__allTests__MockNetworkTests),
        testCase(NetworkGroupTests.__allTests__NetworkGroupTests),
    ]
}
#endif
