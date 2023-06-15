//
//  CNProvider.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine

fileprivate func runOnMain(_ completion: @escaping () -> Void) {
	DispatchQueue.main.async {
		completion()
	}
}

fileprivate func generateSuccess<T: Endpoint, U: Decodable>(for endpoint: T, data: U) -> AnyPublisher<U, Error> {
	runOnMain {
		CNDebugInfo.getLogger(for: endpoint)?.log("Success", mode: .stop)
	}
	return Result.success(data).publisher.eraseToAnyPublisher()
}

fileprivate func generateFailure<T: Endpoint, U: Decodable>(for endpoint: T, error: CNError) -> AnyPublisher<U, Error> {
	runOnMain {
		CNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
	}
	return Fail(error: error).eraseToAnyPublisher()
}

@available(macOS 10.15, *)
open class CNProvider<T: Endpoint> {
	private var didRetry: [String] = []
	private let endpointURLMapper: EndpointURLMapper
	
	public typealias EndpointURLMapper = (Endpoint) -> URL?
	
	public init(endpointURLMapper: @escaping EndpointURLMapper = defaultURLMapper) {
		self.endpointURLMapper = endpointURLMapper
	}
    
    open func task<U: Decodable>(
        for endpoint: T,
        responseType: U.Type,
        decoder: JSONDecoder? = nil,
        ignorePinning: Bool = false,
        callbackTask: (() async throws -> AccessTokenConvertible)?
    ) async throws -> U {
        runOnMain {
            CNDebugInfo.createLogger(for: endpoint)
        }
        guard let urlRequest = prepareRequest(for: endpoint) else {
            runOnMain {
                CNDebugInfo.getLogger(for: endpoint)?.log(CNError(type: .failedToBuildRequest).localizedDescription, mode: .stop)
            }
            
            throw CNError(type: .failedToBuildRequest)
        }
        
        let session = CNConfig.getSession(ignorePinning: ignorePinning)
        
        let (data, urlResponse) = try await session.data(for: urlRequest)
        
        if let response = urlResponse as? HTTPURLResponse,
           response.statusCode == 401 && !didRetry.contains(endpoint.caseIdentifier),
           let callback = callbackTask {
            didRetry.append(endpoint.caseIdentifier)
            
            let token = try await callback().convert()
            
            CNConfig.setAccessToken(token, for: endpoint)
            
            return try await self.task(for: endpoint,
                                       responseType: U.self,
                                       decoder: decoder,
                                       ignorePinning: ignorePinning,
                                       callbackTask: callbackTask)
        }
        
        return try (decoder ?? endpoint.jsonDecoder).decode(U.self, from: data)
    }
	
	/// Returns publisher which automatically converts the response data into given response type
    open func publisher<U: Decodable>(
        for endpoint: T,
        responseType: U.Type,
        decoder: JSONDecoder? = nil,
        retries: Int = 0,
        expectedStatusCodes: [Int] = [200, 201, 204],
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<U, Error> {
		rawPublisher(for: endpoint,
					 retries: retries,
					 expectedStatusCodes: expectedStatusCodes,
					 ignorePinning: ignorePinning,
					 receiveOn: queue)
		.flatMap { data -> AnyPublisher<U, Error> in
			do {
				let response = try (decoder ?? endpoint.jsonDecoder).decode(U.self, from: data)
				return generateSuccess(for: endpoint, data: response)
			} catch {
				let error = CNError(type: .failedToMapResponse, data: data)
				return generateFailure(for: endpoint, error: error)
			}
		}
		.retry(retries)
		.receive(on: queue)
		.eraseToAnyPublisher()
	}
	
	/// Returns publisher with raw data in the response
	open func rawPublisher(
        for endpoint: T,
        retries: Int = 0,
        expectedStatusCodes: [Int] = [200, 201, 204],
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<Data, Error> {
		runOnMain {
			CNDebugInfo.createLogger(for: endpoint)
		}
		return prepPublisher(for: endpoint, ignorePinning: ignorePinning)
			.flatMap { [weak self] output -> AnyPublisher<Data, Error> in
				guard let response = output.response as? HTTPURLResponse else {
					let error = CNError(type: .failedToMapResponse)
					return generateFailure(for: endpoint, error: error)
				}
				
				if response.statusCode == 401 && !(self?.didRetry.contains(endpoint.caseIdentifier) ?? false), let publisher = endpoint.callbackPublisher {
					let errorDetails = CNErrorDetails(statusCode: response.statusCode,
													  localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
													  url: response.url,
													  mimeType: response.mimeType,
													  headers: response.allHeaderFields,
													  data: output.data)
					self?.didRetry.append(endpoint.caseIdentifier)
					return publisher.flatMap { [weak self] response -> AnyPublisher<Data, Error> in
						let error = CNError(type: .authenticationFailed, details: errorDetails)
						guard let token = (response as? CNAccessToken) ?? response.convert() else {
							return generateFailure(for: endpoint, error: error)
						}
						CNConfig.setAccessToken(token, for: endpoint)
						
						guard let newPublisher = self?.prepPublisher(for: endpoint, ignorePinning: ignorePinning).map(\.data).eraseToAnyPublisher() else {
							return generateFailure(for: endpoint, error: error)
						}
						
						return newPublisher
					}.eraseToAnyPublisher()
				} else if response.statusCode == 401 {
					self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
					let error = CNError(type: .authenticationFailed,
										details: .init(statusCode: response.statusCode,
													   localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
													   url: response.url,
													   mimeType: response.mimeType,
													   headers: response.allHeaderFields),
										data: output.data)
					return generateFailure(for: endpoint, error: error)
				}
				
				self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
				guard expectedStatusCodes.contains(response.statusCode) else {
					let error = CNError(type: .unexpectedResponse,
										details: .init(statusCode: response.statusCode,
													   localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
													   url: response.url,
													   mimeType: response.mimeType,
													   headers: response.allHeaderFields),
										data: output.data)
					return generateFailure(for: endpoint, error: error)
				}
				
				guard output.data.count > 0 else {
					return generateFailure(for: endpoint, error: CNError(type: .emptyResponse))
				}
				
				return Result.success(output.data).publisher.eraseToAnyPublisher()
			}
			.retry(retries)
			.receive(on: queue)
			.eraseToAnyPublisher()
	}
	
	
	/// Returns publisher which gives you updates on upload progress until the task is complete
    open func uploadPublisher<U: Codable>(
        for endpoint: T,
        responseType: U.Type,
        retries: Int = 0,
        decoder: JSONDecoder? = nil,
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<UploadResponse<U>, Error> {
		runOnMain {
			CNDebugInfo.createLogger(for: endpoint)
		}
		return prepUploadPublisher(for: endpoint, responseType: responseType,
								   decoder: decoder, ignorePinning: ignorePinning)
		.flatMap { [weak self] response -> AnyPublisher<UploadResponse, Error> in
			if response == .authError && !(self?.didRetry.contains(endpoint.caseIdentifier) ?? false), let publisher = endpoint.callbackPublisher {
				let errorDetails = CNErrorDetails(statusCode: 401,
												  localizedString: HTTPURLResponse.localizedString(forStatusCode: 401))
				let error = CNError(type: .authenticationFailed, details: errorDetails)
				self?.didRetry.append(endpoint.caseIdentifier)
				
				return publisher.flatMap { [weak self] response -> AnyPublisher<UploadResponse, Error> in
					guard let token = (response as? CNAccessToken) ?? response.convert() else {
						runOnMain {
							CNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
						}
						
						return Fail(error: error).eraseToAnyPublisher()
					}
					CNConfig.setAccessToken(token, for: endpoint)
					
					return self?.prepUploadPublisher(for: endpoint, responseType: responseType, decoder: decoder, ignorePinning: ignorePinning) ?? Fail(error: error).eraseToAnyPublisher()
				}.eraseToAnyPublisher()
			} else if response == .authError {
				self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
				let errorDetails = CNErrorDetails(statusCode: 401,
												  localizedString: HTTPURLResponse.localizedString(forStatusCode: 401))
				let error = CNError(type: .authenticationFailed, details: errorDetails)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
				}
				
				return Fail(error: error).eraseToAnyPublisher()
			} else if case .error(let errorCode, let errorData) = response {
				let errorDetails = CNErrorDetails(statusCode: errorCode,
												  localizedString: HTTPURLResponse.localizedString(forStatusCode: errorCode))
				let error = CNError(type: .unexpectedResponse, details: errorDetails, data: errorData)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
				}
				
				return Fail(error: error).eraseToAnyPublisher()
			}
			
			self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
			
			return Result.success(response).publisher.eraseToAnyPublisher()
		}
		.retry(retries)
		.receive(on: queue)
		.eraseToAnyPublisher()
	}

	private func prepareRequest(for endpoint: Endpoint, withBody: Bool = true) -> URLRequest? {
		guard let url = endpointURLMapper(endpoint) else { return nil }
		var request = URLRequest(url: url)
		prepareHeadersAndMethod(endpoint: endpoint, request: &request)
		if withBody {
			prepareBody(endpointData: endpoint.data, boundary: endpoint.boundary, request: &request)
		}
		runOnMain {
			CNDebugInfo.getLogger(for: endpoint)?.log("\n" + request.cURL(pretty: true), mode: .start)
		}
		
		return request
	}
	
	private func prepareHeadersAndMethod(endpoint: Endpoint, request: inout URLRequest) {
		endpoint.headers?.forEach { key, value in
			request.addValue("\(value)", forHTTPHeaderField: key)
		}
		if endpoint.requiresAccessToken {
			let token = CNConfig.accessToken(for: endpoint)?.access_token
			request.addValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
		}
		request.addValue("Safari/CombineNetworking", forHTTPHeaderField: "User-Agent")
		request.httpMethod = endpoint.method.rawValue.uppercased()
	}
	
	private func prepareBody(endpointData: EndpointData, boundary: Boundary?, request: inout URLRequest) {
		CNDataEncoder.encode(endpointData, boundary: boundary, request: &request)
	}
	
	private func prepPublisher(for endpoint: T, ignorePinning: Bool) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
		guard let urlRequest = prepareRequest(for: endpoint) else {
			runOnMain {
				CNDebugInfo.getLogger(for: endpoint)?.log(CNError(type: .failedToBuildRequest).localizedDescription, mode: .stop)
			}
			
			return Fail(error: CNError(type: .failedToBuildRequest)).eraseToAnyPublisher()
		}
		
		return CNConfig.getSession(ignorePinning: ignorePinning).dataTaskPublisher(for: urlRequest)
			.mapError { urlError -> Error in
				let networkErrorCodes = [
					NSURLErrorNetworkConnectionLost,
					NSURLErrorNotConnectedToInternet,
					NSURLErrorCannotLoadFromNetwork
				]
				let errorType: CNError.ErrorType = networkErrorCodes.contains(urlError.errorCode) ? .noInternetConnection : .unexpectedResponse
				let errorDetails = CNErrorDetails(statusCode: urlError.errorCode,
												  localizedString: urlError.localizedDescription)
				let error = CNError(type: errorType, details: errorDetails)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
				}
				
				return error
			}
			.eraseToAnyPublisher()
	}
	
	private func prepUploadPublisher<U: Codable>(
        for endpoint: T,
        responseType: U.Type,
        decoder: JSONDecoder? = nil,
        ignorePinning: Bool
    ) -> AnyPublisher<UploadResponse<U>, Error> {
		guard let urlRequest = prepareRequest(for: endpoint, withBody: false),
			  let data = CNDataEncoder.prepareUploadBody(endpointData: endpoint.data, boundary: endpoint.boundary) else {
			runOnMain {
				CNDebugInfo.getLogger(for: endpoint)?.log(CNError(type: .failedToBuildRequest).localizedDescription, mode: .stop)
			}
			
			return Fail(error: CNError(type: .failedToBuildRequest)).eraseToAnyPublisher()
		}
		
		let publisher: PassthroughSubject<UploadResponse<U>, Error> = .init()
		let session = CNConfig.getSession(ignorePinning: ignorePinning)
		let sessionDelegate = session.delegate as! CNSimpleSessionDelegate
			
		let task = session.uploadTask(with: urlRequest, from: data) { data, response, error in
			if let error = error {
				publisher.send(completion: .failure(error))
				return
			}
			
			if (response as? HTTPURLResponse)?.statusCode == 200, let data = data {
				do {
					let response = try (decoder ?? endpoint.jsonDecoder).decode(U.self, from: data)
					publisher.send(.response(data: response))
					return
				} catch {
					#if DEBUG
					print(error.localizedDescription)
					#endif
				}
			} else if (response as? HTTPURLResponse)?.statusCode == 401 {
				publisher.send(.authError)
				return
			} else if let urlResponse = response as? HTTPURLResponse {
				publisher.send(.error(urlResponse.statusCode, data))
				return
			}
			
			publisher.send(.response(data: nil))
		}
		task.resume()
		
		return sessionDelegate.uploadProgress
			.filter { $0.id == task.taskIdentifier }
			.setFailureType(to: Error.self)
			.map { .progress(percentage: $0.progress) }
			.merge(with: publisher)
			.eraseToAnyPublisher()
	}
}
