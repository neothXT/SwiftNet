//
//  SNProvider + Test.swift
//  
//
//  Created by Maciej Burdzicki on 23/01/2023.
//

import Foundation
import Combine

public extension SNProvider where T: Endpoint {
	
	/// Performs simple test checking if the status code and the response model met the expectations set for a given endpoint
	func test<U: Codable>(_ endpoint: T,
						  responseType: U.Type,
						  usingMocks: Bool,
						  storeIn store: inout Set<AnyCancellable>,
						  failOnFinishedReceived: Bool = true,
						  onSuccess: @escaping (U?) -> Void) {
		test(endpoint, responseType: responseType, usingMocks: usingMocks, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) {
			onSuccess($0)
		} onFailure: { _ in }
	}
	
	/// Performs simple test checking if the status code and the response model met the expectations set for a given endpoint
	func test<U: Codable>(_ endpoint: T,
						  responseType: U.Type,
						  usingMocks: Bool,
						  storeIn store: inout Set<AnyCancellable>,
						  failOnFinishedReceived: Bool = true,
						  onFailure: @escaping (Error) -> Void) {
		test(endpoint, responseType: responseType, usingMocks: usingMocks, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) { _ in } onFailure: {
			onFailure($0)
		}
	}
	
	/// Performs simple test checking if the status code and the response model met the expectations set for a given endpoint
	func test<U: Codable>(_ endpoint: T,
						  responseType: U.Type,
						  usingMocks: Bool,
						  storeIn store: inout Set<AnyCancellable>,
						  failOnFinishedReceived: Bool = true,
						  onSuccess: @escaping (U?) -> Void,
						  onFailure: @escaping (Error) -> Void) {
		testPublisher(for: endpoint, responseType: responseType, usingMocks: usingMocks)
			.sink {
				switch $0 {
				case .failure(let error):
					onFailure(error)
				case .finished:
					failOnFinishedReceived ? onFailure(SNError(type: .requestFinished)) : onSuccess(nil)
				}
			} receiveValue: { model in
				onSuccess(model)
			}
			.store(in: &store)
	}
	
	/// Performs simple test checking if the status code of the response met the expectations set for a given endpoint
	func testRaw(_ endpoint: T,
				 usingMocks: Bool,
				 storeIn store: inout Set<AnyCancellable>,
				 failOnFinishedReceived: Bool = true,
				 onSuccess: @escaping () -> Void) {
		testRaw(endpoint, usingMocks: usingMocks, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) {
			onSuccess()
		} onFailure: { _ in }
	}
	
	/// Performs simple test checking if the status code of the response met the expectations set for a given endpoint
	func testRaw(_ endpoint: T,
				 usingMocks: Bool,
				 storeIn store: inout Set<AnyCancellable>,
				 failOnFinishedReceived: Bool = true,
				 onFailure: @escaping (Error) -> Void) {
		testRaw(endpoint, usingMocks: usingMocks, storeIn: &store, failOnFinishedReceived: failOnFinishedReceived) { } onFailure: {
			onFailure($0)
		}
	}
	
	/// Performs simple test checking if the status code of the response met the expectations set for a given endpoint
	func testRaw(_ endpoint: T,
				 usingMocks: Bool,
				 storeIn store: inout Set<AnyCancellable>,
				 failOnFinishedReceived: Bool = true,
				 onSuccess: @escaping () -> Void,
				 onFailure: @escaping (Error) -> Void) {
		testPublisher(for: endpoint, responseType: Data.self, usingMocks: usingMocks)
			.sink {
				switch $0 {
				case .failure(let error):
					onFailure(error)
				case .finished:
					failOnFinishedReceived ? onFailure(SNError(type: .requestFinished)) : onSuccess()
				}
			} receiveValue: { _ in
				onSuccess()
			}
			.store(in: &store)
	}
	
	private func testPublisher<U: Decodable>(for endpoint: T, responseType: U.Type, usingMocks: Bool) -> AnyPublisher<U, Error> {
		let optionalRawPublisher = rawPublisher(for: endpoint) as? AnyPublisher<U, Error>
        return usingMocks ? mockPublisher(for: endpoint, responseType: U.self) : (optionalRawPublisher ?? publisher(for: endpoint, responseType: U.self, decoder: endpoint.jsonDecoder))
	}
}

fileprivate extension SNProvider {
	func mockPublisher<U: Decodable>(for endpoint: T,
									 responseType: U.Type,
									 receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error> {
		guard let data = endpoint.mockedData as? U else {
			return Result.failure(SNError(type: .failedToMapResponse)).publisher.eraseToAnyPublisher()
		}
		
		return Result.success(data).publisher.eraseToAnyPublisher()
	}
}
