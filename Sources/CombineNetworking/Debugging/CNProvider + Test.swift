//
//  CNProvider + Test.swift
//  
//
//  Created by Maciej Burdzicki on 23/01/2023.
//

import Foundation
import Combine

public extension CNProvider where T: Endpoint {
	
	/// Performs simple test checking if the status code and the response model met the expectations set for a given endpoint
	func test<U: Codable>(_ endpoint: T,
						  responseType: U.Type,
						  storeIn store: inout Set<AnyCancellable>,
						  failOnFinishedReceived: Bool = true,
						  onSuccess: @escaping () -> Void) {
		test(endpoint, responseType: responseType, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) {
			onSuccess()
		} onFailure: { _ in }
	}
	
	/// Performs simple test checking if the status code and the response model met the expectations set for a given endpoint
	func test<U: Codable>(_ endpoint: T,
						  responseType: U.Type,
						  storeIn store: inout Set<AnyCancellable>,
						  failOnFinishedReceived: Bool = true,
						  onFailure: @escaping (Error) -> Void) {
		test(endpoint, responseType: responseType, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) { } onFailure: {
			onFailure($0)
		}
	}
	
	/// Performs simple test checking if the status code and the response model met the expectations set for a given endpoint
	func test<U: Codable>(_ endpoint: T,
						  responseType: U.Type,
						  storeIn store: inout Set<AnyCancellable>,
						  failOnFinishedReceived: Bool = true,
						  onSuccess: @escaping () -> Void,
						  onFailure: @escaping (Error) -> Void) {
		publisher(for: endpoint, responseType: responseType)
			.sink {
				switch $0 {
				case .failure(let error):
					onFailure(error)
				case .finished:
					failOnFinishedReceived ? onFailure(CNError(type: .requestFinished)) : onSuccess()
				}
			} receiveValue: { _ in
				onSuccess()
			}
			.store(in: &store)
	}
	
	/// Performs simple test checking if the status code of the response met the expectations set for a given endpoint
	func testRaw(_ endpoint: T,
			  storeIn store: inout Set<AnyCancellable>,
			  failOnFinishedReceived: Bool = true,
			  onSuccess: @escaping () -> Void) {
		testRaw(endpoint, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) {
			onSuccess()
		} onFailure: { _ in }
	}
	
	/// Performs simple test checking if the status code of the response met the expectations set for a given endpoint
	func testRaw(_ endpoint: T,
			  storeIn store: inout Set<AnyCancellable>,
			  failOnFinishedReceived: Bool = true,
			  onFailure: @escaping (Error) -> Void) {
		testRaw(endpoint, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) { } onFailure: {
			onFailure($0)
		}
	}
	
	/// Performs simple test checking if the status code of the response met the expectations set for a given endpoint
	func testRaw(_ endpoint: T,
			  storeIn store: inout Set<AnyCancellable>,
			  failOnFinishedReceived: Bool = true,
			  onSuccess: @escaping () -> Void,
			  onFailure: @escaping (Error) -> Void) {
		rawPublisher(for: endpoint)
			.sink {
				switch $0 {
				case .failure(let error):
					onFailure(error)
				case .finished:
					failOnFinishedReceived ? onFailure(CNError(type: .requestFinished)) : onSuccess()
				}
			} receiveValue: { _ in
				onSuccess()
			}
			.store(in: &store)
	}
}
