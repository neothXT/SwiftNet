//
//  AccessTokenManipulationTests.swift
//  
//
//  Created by Maciej Burdzicki on 24/04/2023.
//

import XCTest
@testable import SwiftNet

final class AccessTokenManipulationTests: XCTestCase {
	private let provider = SNProvider<RemoteEndpoint>()

	func testStoreToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = SNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		SNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((SNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
	}
    
    func testStoreModelToken() throws {
        let endpoint = TestEndpoint()
        let sampleToken = SNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
        
        SNConfig.setAccessToken(sampleToken, for: endpoint)
        XCTAssert((SNConfig.accessToken(for: endpoint)?.access_token ?? "") == "aaa")
    }
    
    func testStoreBuilderToken() throws {
        let builder = TestEndpoint().comments
        let sampleToken = SNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
        
        SNConfig.setAccessToken(sampleToken, for: builder)
        XCTAssert((SNConfig.accessToken(for: builder)?.access_token ?? "") == "aaa")
    }
	
	func testFetchTokenByStoringLabel() throws {
		let sampleToken = SNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		SNConfig.setAccessToken(sampleToken, for: "someLabel")
		XCTAssert((SNConfig.accessToken(for: "someLabel")?.access_token ?? "") == "aaa")
	}
	
	func testFetchGlobalToken() throws {
		let endpoint: RemoteEndpoint = .stringGet("")
		let sampleToken = SNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		SNConfig.setAccessToken(sampleToken, for: endpoint)
		XCTAssert((SNConfig.globalAccessToken()?.access_token ?? "") == "aaa")
	}
	
	func testRemoveToken() throws {
		let endpoint: RemoteEndpoint = .todos
		let sampleToken = SNAccessToken(access_token: "aaa", expires_in: nil, refresh_token: nil, scope: nil)
		
		SNConfig.setAccessToken(sampleToken, for: endpoint)
		SNConfig.removeAccessToken(for: endpoint)
		
		XCTAssert(SNConfig.accessToken(for: endpoint) == nil)
	}
}
