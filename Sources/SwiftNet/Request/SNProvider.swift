//
//  SNProvider.swift
//  SwiftNet
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
@_exported import Combine
@_exported import SNUtilities
@_exported import SwiftNetMacros

fileprivate func runOnMain(_ completion: @escaping () -> Void) {
    DispatchQueue.main.async {
        completion()
    }
}

fileprivate func generateSuccess<T: Endpoint, U: Decodable>(for endpoint: T, data: U) -> AnyPublisher<U, Error> {
    runOnMain {
        SNDebugInfo.getLogger(for: endpoint)?.log("Success", mode: .stop)
    }
    return Result.success(data).publisher.eraseToAnyPublisher()
}

fileprivate func generateFailure<T: Endpoint, U: Decodable>(for endpoint: T, error: SNError) -> AnyPublisher<U, Error> {
    runOnMain {
        SNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
    }
    return Fail(error: error).eraseToAnyPublisher()
}

@available(macOS 10.15, *)
open class SNProvider<T: Endpoint> {
    private var didRetry: [String] = []
    private let endpointURLMapper: EndpointURLMapper
    
    public typealias EndpointURLMapper = (Endpoint) -> URL?
    
    public init(endpointURLMapper: @escaping EndpointURLMapper = defaultURLMapper) {
        self.endpointURLMapper = endpointURLMapper
    }
    
    /// Executes dataTask and automatically maps the response to desired type
    open func task<U: Decodable>(
        for endpoint: T,
        responseType: U.Type,
        expectedStatusCodes: [Int] = [200, 201, 204],
        decoder: JSONDecoder? = nil,
        ignorePinning: Bool = false
    ) async throws -> U {
        runOnMain {
            SNDebugInfo.createLogger(for: endpoint)
        }
        guard let urlRequest = prepareRequest(for: endpoint) else {
            runOnMain {
                SNDebugInfo.getLogger(for: endpoint)?.log(SNError(type: .failedToBuildRequest).localizedDescription, mode: .stop)
            }
            throw SNError(type: .failedToBuildRequest)
        }
        
        let session = SNConfig.getSession(ignorePinning: ignorePinning)
        var data: Data?
        var urlResponse: URLResponse?
        do {
            (data, urlResponse) = try await session.data(for: urlRequest)
        } catch {
            let networkErrorCodes = [
                NSURLErrorNetworkConnectionLost,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorCannotLoadFromNetwork
            ]
            let error = error as NSError
            let errorType: SNError.ErrorType = networkErrorCodes.contains(error.code) ? .noInternetConnection : .unexpectedResponse
            let errorDetails = SNErrorDetails(statusCode: error.code,
                                              localizedString: error.localizedDescription)
            let SNError = SNError(type: errorType, details: errorDetails)
            runOnMain {
                SNDebugInfo.getLogger(for: endpoint)?.log(SNError.localizedDescription, mode: .stop)
            }
            throw SNError
        }
        
        
        
        guard let response = urlResponse as? HTTPURLResponse else {
            runOnMain {
                SNDebugInfo.getLogger(for: endpoint)?.log(SNError(type: .failedToMapResponse).localizedDescription, mode: .stop)
            }
            throw SNError(type: .failedToMapResponse)
        }
        
        guard expectedStatusCodes.contains(response.statusCode) else {
            runOnMain {
                SNDebugInfo.getLogger(for: endpoint)?.log(SNError(type: .unexpectedResponse).localizedDescription, mode: .stop)
            }
            throw SNError(
                type: .unexpectedResponse,
                details: .init(
                    statusCode: response.statusCode,
                    localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                    url: response.url,
                    mimeType: response.mimeType,
                    headers: response.allHeaderFields),
                data: data
            )
        }
        
        if SNConfig.accessTokenErrorCodes.contains(response.statusCode) {
            var convertibleToken: AccessTokenConvertible? = try await endpoint.callbackTask?()
            
            if convertibleToken == nil {
                convertibleToken = try await endpoint.callbackPublisher?.toAsyncTask()
            }
            
            let identifier = endpointURLMapper(endpoint)?.absoluteString ?? endpoint.path
            
            if !didRetry.contains(identifier), let token = convertibleToken?.convert() {
                 didRetry.append(identifier)
                 SNConfig.setAccessToken(token, for: endpoint)
                 
                 return try await self.task(for: endpoint,
                                            responseType: U.self,
                                            decoder: decoder,
                                            ignorePinning: ignorePinning)
            } else {
                runOnMain {
                    SNDebugInfo.getLogger(for: endpoint)?.log(SNError(type: .authenticationFailed).localizedDescription, mode: .stop)
                }
                throw SNError(
                    type: .authenticationFailed,
                    details: .init(
                        statusCode: response.statusCode,
                        localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                        url: response.url,
                        mimeType: response.mimeType,
                        headers: response.allHeaderFields),
                    data: nil
                )
            }
        }
        
        if let castedData = data as? U {
            runOnMain {
                SNDebugInfo.getLogger(for: endpoint)?.log("Success", mode: .stop)
            }
            return castedData
        }
        
        guard let data, let decodedData = try? (decoder ?? endpoint.jsonDecoder).decode(U.self, from: data) else {
            runOnMain {
                SNDebugInfo.getLogger(for: endpoint)?.log(SNError(type: .failedToMapResponse).localizedDescription, mode: .stop)
            }
            throw SNError(type: .failedToMapResponse)
        }
        
        runOnMain {
            SNDebugInfo.getLogger(for: endpoint)?.log("Success", mode: .stop)
        }
        return decodedData
    }
    
    /// Returns publisher which automatically converts the response data into given response type
    open func publisher<U: Decodable>(
        for endpoint: T,
        responseType: U.Type,
        decoder: JSONDecoder? = nil,
        expectedStatusCodes: [Int] = [200, 201, 204],
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<U, Error> {
        let wrapper: PassthroughSubject<U, Error> = .init()
        
        Task {
            do {
                let data = try await task(
                    for: endpoint,
                    responseType: responseType,
                    expectedStatusCodes: expectedStatusCodes,
                    decoder: decoder,
                    ignorePinning: ignorePinning
                )
                
                wrapper.send(data)
            } catch {
                wrapper.send(completion: .failure(error))
            }
        }
        
        return wrapper.eraseToAnyPublisher()
    }
    
    /// Returns publisher with raw data in the response
    open func rawPublisher(
        for endpoint: T,
        retries: Int = 0,
        expectedStatusCodes: [Int] = [200, 201, 204],
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<Data, Error> {
        publisher(for: endpoint, responseType: Data.self, expectedStatusCodes: expectedStatusCodes, ignorePinning: ignorePinning, receiveOn: queue)
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
			SNDebugInfo.createLogger(for: endpoint)
		}
		return prepUploadPublisher(for: endpoint, responseType: responseType,
								   decoder: decoder, ignorePinning: ignorePinning)
		.flatMap { [weak self] response -> AnyPublisher<UploadResponse, Error> in
            let identifier = self?.endpointURLMapper(endpoint)?.absoluteString ?? endpoint.path
			if response == .authError && !(self?.didRetry.contains(identifier) ?? false), let publisher = endpoint.callbackPublisher {
				let errorDetails = SNErrorDetails(statusCode: 401,
												  localizedString: HTTPURLResponse.localizedString(forStatusCode: 401))
				let error = SNError(type: .authenticationFailed, details: errorDetails)
				self?.didRetry.append(identifier)
				
				return publisher.flatMap { [weak self] response -> AnyPublisher<UploadResponse, Error> in
					guard let token = (response as? SNAccessToken) ?? response.convert() else {
						runOnMain {
							SNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
						}
						
						return Fail(error: error).eraseToAnyPublisher()
					}
					SNConfig.setAccessToken(token, for: endpoint)
					
					return self?.prepUploadPublisher(for: endpoint, responseType: responseType, decoder: decoder, ignorePinning: ignorePinning) ?? Fail(error: error).eraseToAnyPublisher()
				}.eraseToAnyPublisher()
			} else if response == .authError {
				self?.didRetry.removeAll { $0 == identifier }
				let errorDetails = SNErrorDetails(statusCode: 401,
												  localizedString: HTTPURLResponse.localizedString(forStatusCode: 401))
				let error = SNError(type: .authenticationFailed, details: errorDetails)
				runOnMain {
					SNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
				}
				
				return Fail(error: error).eraseToAnyPublisher()
			} else if case .error(let errorCode, let errorData) = response {
				let errorDetails = SNErrorDetails(statusCode: errorCode,
												  localizedString: HTTPURLResponse.localizedString(forStatusCode: errorCode))
				let error = SNError(type: .unexpectedResponse, details: errorDetails, data: errorData)
				runOnMain {
					SNDebugInfo.getLogger(for: endpoint)?.log(error.localizedDescription, mode: .stop)
				}
				
				return Fail(error: error).eraseToAnyPublisher()
			}
			
			self?.didRetry.removeAll { $0 == identifier }
			
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
			SNDebugInfo.getLogger(for: endpoint)?.log("\n" + request.cURL(pretty: true), mode: .start)
		}
		
		return request
	}
	
	private func prepareHeadersAndMethod(endpoint: Endpoint, request: inout URLRequest) {
		endpoint.headers?.forEach { key, value in
			request.addValue("\(value)", forHTTPHeaderField: key)
		}
		if endpoint.requiresAccessToken {
			let token = SNConfig.accessToken(for: endpoint)?.access_token
			request.addValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
		}
		request.addValue("Safari/SwiftNet", forHTTPHeaderField: "User-Agent")
		request.httpMethod = endpoint.method.rawValue.uppercased()
	}
	
	private func prepareBody(endpointData: EndpointData, boundary: Boundary?, request: inout URLRequest) {
		SNDataEncoder.encode(endpointData, boundary: boundary, request: &request)
	}
	
	private func prepUploadPublisher<U: Codable>(
        for endpoint: T,
        responseType: U.Type,
        decoder: JSONDecoder? = nil,
        ignorePinning: Bool
    ) -> AnyPublisher<UploadResponse<U>, Error> {
		guard let urlRequest = prepareRequest(for: endpoint, withBody: false),
			  let data = SNDataEncoder.prepareUploadBody(endpointData: endpoint.data, boundary: endpoint.boundary) else {
			runOnMain {
				SNDebugInfo.getLogger(for: endpoint)?.log(SNError(type: .failedToBuildRequest).localizedDescription, mode: .stop)
			}
			
			return Fail(error: SNError(type: .failedToBuildRequest)).eraseToAnyPublisher()
		}
		
		let publisher: PassthroughSubject<UploadResponse<U>, Error> = .init()
		let session = SNConfig.getSession(ignorePinning: ignorePinning)
		let sessionDelegate = session.delegate as! SNSimpleSessionDelegate
			
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
