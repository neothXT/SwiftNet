import XCTest
import Combine
import Reachability
@testable import CombineNetworking

final class CombineNetworkingTests: XCTestCase {
	private let provider = CNProvider<RemoteEndpoint>()
	
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
		
		CNNetworkMonitor.publisher()
			.sink { status in
				if status == .unavailable {
					expectation.fulfill()
				}
			}
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testStoreToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
	}
	
	func testFetchTokenByStrategy() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: RemoteEndpoint.self)?.access_token ?? "") == "aaa")
	}
	
	func testFetchTokenByStoringLabel() throws {
		let endpoint: RemoteEndpoint = .posts
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: "someLabel")?.access_token ?? "") == "aaa")
	}
	
	func testFetchGlobalToken() throws {
		let endpoint: RemoteEndpoint = .stringGet("")
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.globalAccessToken()?.access_token ?? "") == "aaa")
	}
	
	func testRemoveToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
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
	
	func testToDictionaryWithEmptyArray() throws {
		let model = TestParamsModelWithArray(name: "First", lastname: "Last", age: 24, array: [])
		XCTAssertFalse(model.toDictionary().contains { $0.key == "array" })
	}
	
	func testToDictionaryWithArray() throws {
		let model = TestParamsModelWithArray(name: "First", lastname: "Last", age: 24, array: ["testValue"])
		XCTAssertTrue(model.toDictionary().contains { $0.key == "array" })
	}
	
	func testToDictionaryWithEmptyDict() throws {
		let model = TestParamsModelWithDict(name: "First", lastname: "Last", age: 24, dict: [:])
		XCTAssertFalse(model.toDictionary().contains { $0.key == "dict" })
	}
	
	func testToDictionaryWithDict() throws {
		let model = TestParamsModelWithDict(name: "First", lastname: "Last", age: 24, dict: ["testKey": "testValue"])
		XCTAssertTrue(model.toDictionary().contains { $0.key == "dict" })
	}
	
	func testToDictionaryWithEmptyEnum() throws {
		let model = TestParamsModelWithEnum(name: "First", lastname: "Last", age: 24, sex: nil)
		XCTAssertFalse(model.toDictionary().contains { $0.key == "sex" })
	}
	
	func testToDictionaryWithEnum() throws {
		let model = TestParamsModelWithEnum(name: "First", lastname: "Last", age: 24, sex: .male)
		XCTAssertTrue(model.toDictionary().contains { ($0.value as? String) == "male" })
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
