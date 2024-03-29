import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SNMacros

final class SwiftNetMacrosTests: XCTestCase {
    func testEndpointMacro() throws {
        assertMacroExpansion(
            """
            @Endpoint(url: "https://apple.com")
            struct MyEndpoint: EndpointModel {
            }
            """,
            expandedSource: 
            """
            struct MyEndpoint: EndpointModel {
            
                let identifier = "MyEndpoint", url = "https://apple.com"
            }
            """,
            macros: ["Endpoint": EndpointMacro.self]
        )
    }
    
    func testGetMacro() throws {
        assertMacroExpansion(
            """
            struct MyEndpoint {
                @GET(url: "/test") var test: EndpointBuilder<Data>
            }
            """,
            expandedSource: """
            struct MyEndpoint {
                var test: EndpointBuilder<Data> {
                    get {
                        .init(
                            url: url + "/test",
                            method: "get",
                            descriptor: .init(),
                            identifier: identifier
                        )
                    }
                }
            }
            """,
            macros: ["GET": GetMacro.self]
        )
    }
    
    func testGetMacroAlt() throws {
        assertMacroExpansion(
            """
            struct MyEndpoint {
                @GET(url: "/test", descriptor: descriptor) var test: EndpointBuilder<Data>
            }
            """,
            expandedSource: """
            struct MyEndpoint {
                var test: EndpointBuilder<Data> {
                    get {
                        .init(
                            url: url + "/test",
                            method: "get",
                            descriptor: descriptor,
                            identifier: identifier
                        )
                    }
                }
            }
            """,
            macros: ["GET": GetMacro.self]
        )
    }
    
    func testNetworkRequestMacro() throws {
        assertMacroExpansion(
            """
            struct MyEndpoint {
                @NetworkRequest(url: "/test", method: "get") var test: EndpointBuilder<Data>
            }
            """,
            expandedSource: """
            struct MyEndpoint {
                var test: EndpointBuilder<Data> {
                    get {
                        .init(
                            url: url + "/test",
                            method: "get",
                            descriptor: .init(),
                            identifier: identifier
                        )
                    }
                }
            }
            """,
            macros: ["NetworkRequest": NetworkRequestMacro.self]
        )
    }
    
    func testNetworkRequestMacroAlt() throws {
        assertMacroExpansion(
            """
            struct MyEndpoint {
                @NetworkRequest(url: "/test", method: "get", descriptor: .init(data: .plain)) var test: EndpointBuilder<Data>
            }
            """,
            expandedSource: """
            struct MyEndpoint {
                var test: EndpointBuilder<Data> {
                    get {
                        .init(
                            url: url + "/test",
                            method: "get",
                            descriptor: .init(data: .plain),
                            identifier: identifier
                        )
                    }
                }
            }
            """,
            macros: ["NetworkRequest": NetworkRequestMacro.self]
        )
    }
    
    func testPostMacro() throws {
        assertMacroExpansion(
                """
                struct MyEndpoint {
                    @POST(url: "/test", descriptor: .init(requiresAccessToken: true)) var test: EndpointBuilder<Data>
                }
                """,
                expandedSource: """
                struct MyEndpoint {
                    var test: EndpointBuilder<Data> {
                        get {
                            .init(
                                url: url + "/test",
                                method: "post",
                                descriptor: .init(requiresAccessToken: true),
                                identifier: identifier
                            )
                        }
                    }
                }
                """,
                macros: ["POST": PostMacro.self]
        )
    }
    
    func testPostMacroAlt() throws {
        assertMacroExpansion(
                """
                struct MyEndpoint {
                    @POST(url: "/test", descriptor: EndpointDescriptor()) var test: EndpointBuilder<Data>
                }
                """,
                expandedSource: """
                struct MyEndpoint {
                    var test: EndpointBuilder<Data> {
                        get {
                            .init(
                                url: url + "/test",
                                method: "post",
                                descriptor: EndpointDescriptor(),
                                identifier: identifier
                            )
                        }
                    }
                }
                """,
                macros: ["POST": PostMacro.self]
        )
    }
    
    func testEndpointMacroFailure() throws {
        assertMacroExpansion(
            """
            @Endpoint(url: "https://apple.com")
            enum MyEndpoint {
            }
            """,
            expandedSource: """
            
            enum MyEndpoint {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Endpoint(url:) can only be applied to a struct or a class", line: 1, column: 1)
            ],
            macros: ["Endpoint": EndpointMacro.self])
    }
    
    func testGetMacroFailure() throws {
        assertMacroExpansion(
            """
            @GET(url: "/test") var test: String
            """,
            expandedSource: """
            var test: String
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@GET(url:) can only be applied to an EndpointBuilder",
                    line: 1,
                    column: 1,
                    fixIts: [.init(message: "Did you mean to use 'EndpointBuilder<String>'?")]
                )
            ],
            macros: ["GET": GetMacro.self])
    }
    
    func testPutMacroFailure() throws {
        assertMacroExpansion(
            """
            @PUT(url: "/test") var test: Data?
            """,
            expandedSource: """
            var test: Data?
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PUT(url:) can only be applied to an EndpointBuilder",
                    line: 1,
                    column: 1,
                    fixIts: [.init(message: "Did you mean to use 'EndpointBuilder<Data?>'?")]
                )
            ],
            macros: ["PUT": PutMacro.self])
    }
}
