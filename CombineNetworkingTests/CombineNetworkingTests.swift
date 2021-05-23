//
//  CombineNetworkingTests.swift
//  CombineNetworkingTests
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import XCTest
import Combine
@testable import CombineNetworking

class CombineNetworkingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testSuccsessfulFetch() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .todos)?
			.sink(receiveCompletion: { _ in
			}) { (todos: Todo) in
				expectation.fulfill()
			}
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}

	func testBadResponseFetch() throws {
		let expectation = expectation(description: "Fetch first todo object")
		var subscriptions: Set<AnyCancellable> = []
		
		CNProvider<RemoteEndpoint>().publisher(for: .posts)?
			.catch { error -> Just<Todo?> in
				if let responseError = error as? CNError, case .badResponse(let response) = responseError,
				   response.statusCode == 404 {
					expectation.fulfill()
				}
				return Just(nil)
			}
			.sink { _ in }
			.store(in: &subscriptions)
		
		wait(for: [expectation], timeout: 10)
	}
}
