//
//  MacroPoweredApproachTests.swift
//
//
//  Created by Maciej Burdzicki on 15/06/2023.
//

import Foundation
import XCTest
@testable import CombineNetworking
import Combine
import CombineNetworkingMacros

final class MacroPoweredApproachTests: XCTestCase {
    let endpoint = TestEndpoint()
    
    func testPlain() throws {
        let expectation = expectation(description: "Test plain fetch")
        var subscriptions: Set<AnyCancellable> = []
        
        endpoint
            .todos
            .setUrlValue("1", forKey: "id")
            .testRaw(storeIn: &subscriptions) {
                expectation.fulfill()
            } onFailure: { _ in }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testModel() throws {
        let expectation = expectation(description: #"Test "test()"#)
        var subscriptions: Set<AnyCancellable> = []
        
        endpoint
            .todos
            .setUrlValue("1", forKey: "id")
            .test(storeIn: &subscriptions) { _ in
                expectation.fulfill()
            } onFailure: { _ in }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testQueryParams() throws {
        let expectation = expectation(description: "Test query params")
        var subscriptions: Set<AnyCancellable> = []
        
        endpoint
            .comments
            .setRequestParams(.queryParams(["postId": 1]))
            .testRaw(storeIn: &subscriptions) {
                expectation.fulfill()
            } onFailure: { _ in }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testPost() throws {
        var subscriptions: Set<AnyCancellable> = []
        let expectation = expectation(description: "Post test should save new post in remote")
        let post = Post(userId: 6, id: 6, title: "Title6", body: "Body6")
        
        
        endpoint
            .post
            .setRequestParams(.jsonModel(post))
            .test(storeIn: &subscriptions) { _ in
                expectation.fulfill()
            } onFailure: { _ in }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testTask() throws {
        let expectation = expectation(description: "Task test should fetch one todo with async/await")
        Task {
            let model = try? await endpoint
                .todos
                .setUrlValue("1", forKey: "id")
                .buildAsync()
            
            if model?.id == 1 {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5)
    }
}
