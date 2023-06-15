import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import CNMacros

let testMacros: [String: Macro.Type] = [
    "Endpoint": EndpointMacro.self,
    "NetworkRequest": NetworkRequestMacro.self,
    "GET": GetMacro.self,
    "POST": PostMacro.self
]

final class CombineNetworkingMacrosTests: XCTestCase {
    func testEndpointMacro() {
        assertMacroExpansion(
            """
            @Endpoint(url: "https://apple.com")
            struct MyEndpoint {
            }
            """,
            expandedSource: """
            
            struct MyEndpoint {
                let url = "https://apple.com"
            }
            """,
            macros: testMacros
        )
    }
    
    func testGetMacro() {
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
                        .init(url: url + "/test", method: "get", headers: defaultHeaders, accessTokenStrategy: defaultAccessTokenStrategy, callbackPublisher: callbackPublisher)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testNetworkRequestMacro() {
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
                        .init(url: url + "/test", method: "get", headers: defaultHeaders, accessTokenStrategy: defaultAccessTokenStrategy, callbackPublisher: callbackPublisher)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testPostMacro() {
        assertMacroExpansion(
                """
                struct MyEndpoint {
                    @POST(url: "/test") var test: EndpointBuilder<Data>
                }
                """,
                expandedSource: """
                struct MyEndpoint {
                    var test: EndpointBuilder<Data> {
                        get {
                            .init(url: url + "/test", method: "post", headers: defaultHeaders, accessTokenStrategy: defaultAccessTokenStrategy, callbackPublisher: callbackPublisher)
                        }
                    }
                }
                """,
                macros: testMacros
        )
    }
}
