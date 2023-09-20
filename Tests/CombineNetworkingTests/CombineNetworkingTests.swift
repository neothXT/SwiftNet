import XCTest
import Combine
@testable import CombineNetworking

final class CombineNetworkingTests: XCTestCase {
	private let provider = CNProvider<RemoteEndpoint>()
	
    // This test should be executed with internet connection turned off
	func testBadResponseFetchNoInternetConnection() throws {
		let expectation = expectation(description: "Test should fail due to no internet connection")
		var subscriptions: Set<AnyCancellable> = []
		
		provider.testRaw(.posts, usingMocks: false, storeIn: &subscriptions) {
			if let error = $0 as? CNError, error.type == .noInternetConnection {
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPlain() throws {
		let expectation = expectation(description: "Test plain fetch")
		var subscriptions: Set<AnyCancellable> = []
		
		provider.testRaw(.todos, usingMocks: false, storeIn: &subscriptions) {
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testModel() throws {
		let expectation = expectation(description: #"Test "test()"#)
		var subscriptions: Set<AnyCancellable> = []
		
		provider.test(.todos, responseType: Todo.self, usingMocks: false, storeIn: &subscriptions) { _ in
			expectation.fulfill()
		} onFailure: { _ in }
		
		wait(for: [expectation], timeout: 10)
	}

	func testQueryParams() throws {
		let expectation = expectation(description: "Test query params")
		var subscriptions: Set<AnyCancellable> = []
		
		provider.testRaw(.dictGet(["postId": 1]), usingMocks: false, storeIn: &subscriptions) {
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testStringQueryParams() throws {
		let expectation = expectation(description: "Test string query params")
		var subscriptions: Set<AnyCancellable> = []
		
		provider.testRaw(.stringGet("postId=1"), usingMocks: false, storeIn: &subscriptions) {
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPostWithJsonModel() throws {
		let post = Post(userId: 123, id: nil, title: "SampleTitle", body: "SampleBody")
		
		let expectation = expectation(description: "Test post with JSON model")
		var subscriptions: Set<AnyCancellable> = []
		
		provider.testRaw(.post(post), usingMocks: false, storeIn: &subscriptions) {
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testPostWithDictionary() throws {
		let expectation = expectation(description: "Test post with dictionary")
		var subscriptions: Set<AnyCancellable> = []
		
		let dict = ["userId": "1231", "title": "Title", "body": "Body"]
		
		provider.testRaw(.dictPost(dict), usingMocks: false, storeIn: &subscriptions) {
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testNetworkMonitor() throws {
		let expectation = expectation(description: "Test network monitor")
		var subscriptions: Set<AnyCancellable> = []
		
		CNNetworkMonitor.shared.publisher()
			.sink { status in
				if status == .unavailable {
					expectation.fulfill()
				}
			}
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 30)
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
	
	func testMockedFetch() throws {
		var subscriptions: Set<AnyCancellable> = []
		let expectation = expectation(description: "Mocked test should return 5 posts")
		
		CNProvider<RemoteEndpoint>().test(.posts, responseType: [Post].self, usingMocks: true, storeIn: &subscriptions) { data in
			if (data ?? []).count == 5 {
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5)
	}
	
	func testMockedPost() throws {
		var subscriptions: Set<AnyCancellable> = []
		let expectation = expectation(description: "Mocked post test should add 1 post to the list and return 6 posts")
		let post = Post(userId: 6, id: 6, title: "Title6", body: "Body6")
		
		CNProvider<RemoteEndpoint>().test(.post(post), responseType: [Post].self, usingMocks: true, storeIn: &subscriptions) { data in
			if (data ?? []).count == 6 {
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5)
	}
}
