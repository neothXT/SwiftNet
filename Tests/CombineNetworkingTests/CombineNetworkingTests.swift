import XCTest
import Combine
@testable import CombineNetworking

final class CombineNetworkingTests: XCTestCase {
	func testBadResponseFetch() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .posts, responseType: Todo?.self)
			.catch { error -> Just<Todo?> in
				if let responseError = error as? CNError, responseError.details?.statusCode != 200 {
					expectation.fulfill()
				}
				return Just(nil)
			}
			.sink { _ in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testBadResponseFetchNoInternetConnection() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .posts, responseType: Todo?.self)
			.catch { error -> Just<Todo?> in
				if let responseError = error as? CNError,
				   responseError.details?.statusCode != 200 && responseError.type == .noInternetConnection {
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
		
		CNProvider<RemoteEndpoint>().publisher(for: .dictGet(["postId": 1]), responseType: [Comment].self)
			.sink(receiveCompletion: { _ in }) { (_: [Comment]) in expectation.fulfill() }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testStringQueryParams() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .stringGet("postId=1"), responseType: [Comment].self)
			.sink(receiveCompletion: { _ in }) { (_: [Comment]) in expectation.fulfill() }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPostWithJsonModel() throws {
		let post = Post(userId: 123, id: nil, title: "SampleTitle", body: "SampleBody")
		
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().rawPublisher(for: .post(post))
			.sink(receiveCompletion: { _ in
			}) { _ in expectation.fulfill() }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPostWithDictionary() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		let dict = ["userId": "1231", "title": "Title", "body": "Body"]
		
		CNProvider<RemoteEndpoint>().rawPublisher(for: .dictPost(dict))
			.sink(receiveCompletion: { _ in
			}) { _ in expectation.fulfill() }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testStoreToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
	}
	
	func testFetchTokenByStrategy() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: RemoteEndpoint.self)?.access_token ?? "") == "aaa")
	}
	
	func testFetchTokenByStoringLabel() throws {
		let endpoint: RemoteEndpoint = .posts
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: "someLabel")?.access_token ?? "") == "aaa")
	}
	
	func testFetchGlobalToken() throws {
		let endpoint: RemoteEndpoint = .stringGet("")
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.globalAccessToken()?.access_token ?? "") == "aaa")
	}
	
	func testRemoveToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", token_type: "", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.storeTokensInKeychain = false
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		CNConfig.removeAccessToken(for: endpoint)
		
		XCTAssert(CNConfig.accessToken(for: endpoint) == nil)
	}
	
	func testUrlEncodedBody() throws {
		let endpoint: RemoteEndpoint = .urlEncodedBody(["name": "Test", "lastname": "Tester"])
		var urlRequest = URLRequest(url: endpoint.baseURL!)
		
		CNDataEncoder.encode(endpoint.data, boundary: nil, request: &urlRequest)
		
		let encodedDataString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
		
		let expectedRasultArray = ["name=Test", "lastname=Tester"]
		var result = true
		
		expectedRasultArray.forEach { result = result && encodedDataString.contains($0) }
		
		XCTAssertTrue(result)
	}
	
	func testUrlEncodedModel() throws {
		let model = TestParamsModel(name: "Test", lastname: "Tester", age: 99)
		let endpoint: RemoteEndpoint = .urlEncoded(model)
		var urlRequest = URLRequest(url: endpoint.baseURL!)
		
		CNDataEncoder.encode(endpoint.data, boundary: nil, request: &urlRequest)
		
		let encodedDataString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
		
		let expectedRasultArray = ["name=Test", "lastname=Tester", "age=99"]
		var result = true
		
		expectedRasultArray.forEach { result = result && encodedDataString.contains($0) }
		
		XCTAssertTrue(result)
	}
	
	func testUrlEncodedModelWithNilValue() throws {
		let model = TestParamsModel(name: "Test", lastname: "Tester", age: nil)
		let endpoint: RemoteEndpoint = .urlEncoded(model)
		var urlRequest = URLRequest(url: endpoint.baseURL!)
		
		CNDataEncoder.encode(endpoint.data, boundary: nil, request: &urlRequest)
		
		let encodedDataString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? ""
		
		let expectedRasultArray = ["name=Test", "lastname=Tester", "age=99"]
		var result = true
		
		expectedRasultArray.forEach { result = result && encodedDataString.contains($0) }
		
		XCTAssertFalse(result)
	}
}
