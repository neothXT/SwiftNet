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

	func testFetch() throws {
		let expectation = expectation(description: "Fetch first todo object")
		let cancellable = CNProvider<RemoteEndpoint>().publisher(for: .todos)?
			.sink(receiveCompletion: { _ in
			}) { (todos: Todo) in
				expectation.fulfill()
			}
		
		wait(for: [expectation], timeout: 10)
	}

}
