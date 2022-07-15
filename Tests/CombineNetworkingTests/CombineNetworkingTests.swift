import XCTest
import Combine
@testable import CombineNetworking

final class CombineNetworkingTests: XCTestCase {
	func testBadResponseFetch() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .posts, responseType: Todo?.self)
			.catch { error -> Just<Todo?> in
				if let responseError = error as? CNError, case .unexpectedResponse(let response) = responseError,
				   response.statusCode == -1003 {
					expectation.fulfill()
				}
				return Just(nil)
			}
			.sink { _ in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPlain() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .todos, responseType: Todo.self)
			.sink(receiveCompletion: { _ in
			}) { (todos: Todo) in
				expectation.fulfill()
			}
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}

	func testQueryParams() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .dictGet(["postId": 1]), responseType: Post.self)
			.sink(receiveCompletion: { _ in
				expectation.fulfill()
			}) { (_: Post) in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testStringQueryParams() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .stringGet("postId=1"), responseType: Post.self)
			.sink(receiveCompletion: { _ in
				expectation.fulfill()
			}) { (_: Post) in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPostWithJsonModel() throws {
		let post = Post(userId: 123, id: nil, title: "SampleTitle", body: "SampleBody")
		
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .post(post), responseType: Post.self)
			.sink(receiveCompletion: { _ in
				expectation.fulfill()
			}) { (_: Post) in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPostWithDictionary() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		let dict = ["userId": "1231", "title": "Title", "body": "Body"]
		
		CNProvider<RemoteEndpoint>().publisher(for: .dictPost(dict), responseType: Post.self)
			.sink(receiveCompletion: { _ in
				expectation.fulfill()
			}) { (_: Post) in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testWebSocketConnection() throws {
		let expectation = expectation(description: "Establish WebSocket connection")
		
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		webSocket.onConnectionEstablished = {
			webSocket.disconnect()
			expectation.fulfill()
		}
		
		webSocket.connect()
		wait(for: [expectation], timeout: 10)
	}
	
	func testWebSoketSendMessage() throws {
		let expectation = expectation(description: "Establish WebSocket connection and send a message")
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		webSocket.connect()
		webSocket.send(.string("Test message")) {
			if let _ = $0 {
				return
			}
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testWebSocketReceiveMessage() throws {
		let expectation = expectation(description: "Establish WebSocket connection and receive a message")
		
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		let receiverWebSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		receiverWebSocket.connect()
		receiverWebSocket.listen { result in
			switch result {
			case .success:
				receiverWebSocket.disconnect()
				expectation.fulfill()
			default:
				return
			}
		}
		
		webSocket.connect()
		webSocket.send(.string("Test message"), completion: { _ in webSocket.disconnect() })
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testStoreToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		
		XCTAssert((CNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
	}
	
	func testRemoveToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		CNConfig.removeAccessToken(for: endpoint)
		
		XCTAssert(CNConfig.accessToken(for: endpoint) == nil)
	}
}
