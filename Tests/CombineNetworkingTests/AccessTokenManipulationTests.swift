//
//  AccessTokenManipulationTests.swift
//  
//
//  Created by Maciej Burdzicki on 24/04/2023.
//

import XCTest
@testable import CombineNetworking

final class AccessTokenManipulationTests: XCTestCase {
	private let provider = CNProvider<RemoteEndpoint>()

	func testStoreToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((CNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
	}
    
    func testStoreModelToken() throws {
        let endpoint = TestEndpoint()
        let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
        
        CNConfig.setAccessToken(sampleToken, for: endpoint)
        XCTAssert((CNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
    }
    
    func testStoreBuilderToken() throws {
        let builder = TestEndpoint().comments
        let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
        
        CNConfig.setAccessToken(sampleToken, for: builder)
        XCTAssert((CNConfig.accessToken(for: builder)?.access_token ?? "") == "aaa")
    }
	
	func testFetchTokenByStoringLabel() throws {
		let sampleToken = CNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		CNConfig.setAccessToken(sampleToken, for: "someLabel")
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
}
