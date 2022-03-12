import XCTest
import Combine
@testable import CombineNetworking

final class CombineNetworkingTests: XCTestCase {
	func testBadResponseFetch() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .posts, responseType: Todo?.self)?
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
		
		CNProvider<RemoteEndpoint>().publisher(for: .todos, responseType: Todo.self)?
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
		
		CNProvider<RemoteEndpoint>().publisher(for: .dictGet(["postId": 1]), responseType: Post.self)?
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
		
		CNProvider<RemoteEndpoint>().publisher(for: .post(post), responseType: Post.self)?
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
		
		CNProvider<RemoteEndpoint>().publisher(for: .dictPost(dict), responseType: Post.self)?
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
	
	func testWebSocketMessage() throws {
		let expectation = expectation(description: "Establish WebSocket connection")
		
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		webSocket.connect()
		webSocket.listen { result in
			switch result {
			case .success:
				webSocket.disconnect()
				expectation.fulfill()
			default:
				return
			}
		}
		wait(for: [expectation], timeout: 10)
	}
}
