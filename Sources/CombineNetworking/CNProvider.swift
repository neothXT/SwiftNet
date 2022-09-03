//
//  CNProvider.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine
import KeychainAccess

fileprivate func runOnMain(_ completion: @escaping () -> Void) {
	DispatchQueue.main.async {
		completion()
	}
}

@available(macOS 10.15, *)
public class CNProvider<T: Endpoint> {
	private var didRetry: [String] = []
	private let endpointURLMapper: EndpointURLMapper
	
	public typealias EndpointURLMapper = (Endpoint) -> URL?
	
	public init(endpointURLMapper: @escaping EndpointURLMapper = defaultURLMapper) {
		self.endpointURLMapper = endpointURLMapper
	}
	
	public func publisher<U: Decodable>(for endpoint: T,
										responseType: U.Type,
										decoder: JSONDecoder? = nil,
										retries: Int = 0,
										expectedStatusCodes: [Int] = [200, 201, 204],
										ignorePinning: Bool = false,
										receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error> {
		rawPublisher(for: endpoint,
					 retries: retries,
					 expectedStatusCodes: expectedStatusCodes,
					 ignorePinning: ignorePinning,
					 receiveOn: queue)
		.flatMap { data -> AnyPublisher<U, Error> in
			do {
				let response = try (decoder ?? endpoint.jsonDecoder).decode(U.self, from: data)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?.log("Success", mode: .stop)
				}
				return Result.success(response).publisher.eraseToAnyPublisher()
			} catch {
				let errorResponse = CNMapErrorResponse(error: error,
													   data: data)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?
						.log(CNError.failedToMapResponse(errorResponse).localizedDescription, mode: .stop)
				}
				return Fail(error: CNError.failedToMapResponse(errorResponse)).eraseToAnyPublisher()
			}
		}
		.retry(retries)
		.receive(on: queue)
		.eraseToAnyPublisher()
	}
	
	public func rawPublisher(for endpoint: T,
							 retries: Int = 0,
							 expectedStatusCodes: [Int] = [200, 201, 204],
							 ignorePinning: Bool = false,
							 receiveOn queue: DispatchQueue = .main) -> AnyPublisher<Data, Error> {
		runOnMain {
			CNDebugInfo.createLogger(for: endpoint)
		}
		return prepPublisher(for: endpoint, ignorePinning: ignorePinning)
			.flatMap { [weak self] output -> AnyPublisher<Data, Error> in
				guard let response = output.response as? HTTPURLResponse else {
					runOnMain {
						CNDebugInfo.getLogger(for: endpoint)?.log(CNError.failedToMapResponse(nil).localizedDescription, mode: .stop)
					}
					return Fail(error: CNError.failedToMapResponse(nil)).eraseToAnyPublisher()
				}
				
				if response.statusCode == 401 && !(self?.didRetry.contains(endpoint.caseIdentifier) ?? false), let publisher = endpoint.callbackPublisher {
					let error = CNUnexpectedErrorResponse(statusCode: response.statusCode,
														  localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
														  url: response.url,
														  mimeType: response.mimeType,
														  headers: response.allHeaderFields,
														  data: output.data)
					self?.didRetry.append(endpoint.caseIdentifier)
					return publisher.flatMap { [weak self] response -> AnyPublisher<Data, Error> in
						guard let token = (response as? CNAccessToken) ?? response.convert() else {
							return Fail(error: CNError.authenticationFailed(error)).eraseToAnyPublisher()
						}
						CNConfig.setAccessToken(token, for: endpoint)
						return self?.prepPublisher(for: endpoint, ignorePinning: ignorePinning).map(\.data).eraseToAnyPublisher() ?? Fail(error: CNError.authenticationFailed(error)).eraseToAnyPublisher()
					}.eraseToAnyPublisher()
				} else if response.statusCode == 401 {
					self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
					let error = CNUnexpectedErrorResponse(statusCode: response.statusCode,
														  localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
														  url: response.url,
														  mimeType: response.mimeType,
														  headers: response.allHeaderFields,
														  data: output.data)
					runOnMain {
						CNDebugInfo.getLogger(for: endpoint)?.log(CNError.authenticationFailed(error).localizedDescription, mode: .stop)
					}
					return Fail(error: CNError.authenticationFailed(error)).eraseToAnyPublisher()
				}
				
				self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
				guard expectedStatusCodes.contains(response.statusCode) else {
					let error = CNUnexpectedErrorResponse(statusCode: response.statusCode,
														  localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
														  url: response.url,
														  mimeType: response.mimeType,
														  headers: response.allHeaderFields,
														  data: output.data)
					runOnMain {
						CNDebugInfo.getLogger(for: endpoint)?.log(CNError.unexpectedResponse(error).localizedDescription, mode: .stop)
					}
					return Fail(error: CNError.unexpectedResponse(error)).eraseToAnyPublisher()
				}
				
				guard output.data.count > 0 else {
					return Fail(error: CNError.emptyResponse).eraseToAnyPublisher()
				}
				
				return Result.success(output.data).publisher.eraseToAnyPublisher()
			}
			.retry(retries)
			.receive(on: queue)
			.eraseToAnyPublisher()
	}
	
	public func uploadPublisher<U: Codable>(for endpoint: T,
											retries: Int = 0,
											responseType: U.Type,
											decoder: JSONDecoder? = nil,
											ignorePinning: Bool = false,
											receiveOn queue: DispatchQueue = .main) -> AnyPublisher<UploadResponse<U>, Error> {
		runOnMain {
			CNDebugInfo.createLogger(for: endpoint)
		}
		return prepUploadPublisher(for: endpoint, responseType: responseType,
								   decoder: decoder, ignorePinning: ignorePinning)
		.flatMap { [weak self] response -> AnyPublisher<UploadResponse, Error> in
			if response == .authError && !(self?.didRetry.contains(endpoint.caseIdentifier) ?? false), let publisher = endpoint.callbackPublisher {
				let error = CNUnexpectedErrorResponse(statusCode: 401,
													  localizedString: HTTPURLResponse.localizedString(forStatusCode: 401),
													  url: nil,
													  mimeType: nil,
													  headers: nil,
													  data: nil)
				self?.didRetry.append(endpoint.caseIdentifier)
				return publisher.flatMap { [weak self] response -> AnyPublisher<UploadResponse, Error> in
					guard let token = (response as? CNAccessToken) ?? response.convert() else {
						return Fail(error: CNError.authenticationFailed(error)).eraseToAnyPublisher()
					}
					CNConfig.setAccessToken(token, for: endpoint)
					return self?.prepUploadPublisher(for: endpoint, responseType: responseType, decoder: decoder, ignorePinning: ignorePinning) ?? Fail(error: CNError.authenticationFailed(error)).eraseToAnyPublisher()
				}.eraseToAnyPublisher()
			} else if response == .authError {
				self?.didRetry.removeAll { $0 == endpoint.caseIdentifier }
				let error = CNUnexpectedErrorResponse(statusCode: 401,
													  localizedString: HTTPURLResponse.localizedString(forStatusCode: 401),
													  url: nil,
													  mimeType: nil,
													  headers: nil,
													  data: nil)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?.log(CNError.authenticationFailed(error).localizedDescription, mode: .stop)
				}
				return Fail(error: CNError.authenticationFailed(error)).eraseToAnyPublisher()
			} else if case .error(let errorCode, let errorData) = response {
				let error = CNUnexpectedErrorResponse(statusCode: errorCode,
													  localizedString: HTTPURLResponse.localizedString(forStatusCode: errorCode),
													  url: nil,
													  mimeType: nil,
													  headers: nil,
													  data: errorData)
				return Fail(error: CNError.unexpectedResponse(error)).eraseToAnyPublisher()
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
		switch endpointData {
		case .queryString(let params):
			guard let url = request.url else { return }
			request.url = URL(string: "\(url)?\(params)")
		case .queryParams(let params):
			guard let url = request.url else { return }
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
			request.url = urlComponents?.url
			
		case .bodyParams(let params):
			guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .jsonModel(let model):
			guard let data = try? model.toJsonData() else { return }
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .urlEncoded(let params):
			guard let data = (params.reduce([]) { $0 + ["\($1.key)=\($1.value)"] }.joined(separator: ",").data(using: .utf8)) else {
					return
				}
			
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .bodyData(let data):
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .plain:
			break
		}
	}
	
	private func prepareUploadBody(endpointData: EndpointData, boundary: Boundary?) -> Data? {
		switch endpointData {
		case .bodyParams(let params):
			guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else { return nil }
			return prepareBodyData(data, boundary: boundary)
		case .jsonModel(let model):
			guard let data = try? model.toJsonData() else { return nil }
			return prepareBodyData(data, boundary: boundary)
		case .bodyData(let data):
			return prepareBodyData(data, boundary: boundary)
		default:
			return nil
		}
	}
	
	private func prepareBodyData(_ data: Data, boundary: Boundary?) -> Data {
		var finalData = Data()
		if let boundary = boundary {
			finalData = boundary.prepareData(withFileData: data)
		} else {
			finalData = data
		}
		return finalData
	}
	
	private func prepPublisher(for endpoint: T, ignorePinning: Bool) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
		guard let urlRequest = prepareRequest(for: endpoint) else {
			return Fail(error: CNError.failedToBuildRequest).eraseToAnyPublisher()
		}
		
		return CNConfig.getSession(ignorePinning: ignorePinning).dataTaskPublisher(for: urlRequest)
			.mapError { urlError -> Error in
				let error = CNUnexpectedErrorResponse(statusCode: urlError.errorCode,
													  localizedString: urlError.localizedDescription,
													  url: urlError.failingURL,
													  mimeType: nil,
													  headers: nil,
													  data: nil)
				runOnMain {
					CNDebugInfo.getLogger(for: endpoint)?.log(CNError.unexpectedResponse(error).localizedDescription, mode: .stop)
				}
				return CNError.unexpectedResponse(error)
			}
			.eraseToAnyPublisher()
	}
	
	private func prepUploadPublisher<U: Codable>(for endpoint: T,
												 responseType: U.Type,
												 decoder: JSONDecoder? = nil,
												 ignorePinning: Bool) -> AnyPublisher<UploadResponse<U>, Error> {
		guard let urlRequest = prepareRequest(for: endpoint, withBody: false),
				let data = prepareUploadBody(endpointData: endpoint.data, boundary: endpoint.boundary) else {
			return Fail(error: CNError.failedToBuildRequest).eraseToAnyPublisher()
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

extension CNConfig {
	fileprivate static var accessTokens: [String: CNAccessToken] = [:]
	
	/// Saves new Access Token
	public static func setAccessToken(_ token: CNAccessToken?, for endpoint: Endpoint) {
		guard let token = token else { return }
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.typeIdentifier
		guard storeTokensInKeychain else {
			accessTokens[key] = token
			return
		}
		
		guard let keychain = CNConfig.keychainInstance else {
			#if DEBUG
			print("Cannot store access token in keychain. Please provide keychain instance using CNConfig.keychainInstance or disable keychain storage by setting CNConfig.storeTokensInKeychain to false!")
			#endif
			return
		}
		
		keychain[data: "accessToken_\(key)"] = try? token.toJsonData()
	}
	
	/// Returns Access Token stored for a given endpoint if present
	public static func accessToken(for endpoint: Endpoint) -> CNAccessToken? {
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.typeIdentifier
		
		guard storeTokensInKeychain else {
			return accessTokens[key]
		}
		
		guard let keychain = CNConfig.keychainInstance else {
			#if DEBUG
			print("Cannot read access token from keychain. Please provide keychain instance using CNConfig.keychainInstance or disable keychain storage by setting CNConfig.storeTokensInKeychain to false!")
			#endif
			return nil
		}
		
		guard let data = keychain[data: "accessToken_\(key)"] else { return nil }
		return try? JSONDecoder().decode(CNAccessToken.self, from: data)
	}
	
	/// Removes stored Access Token for a given endpoint if present
	@discardableResult
	public static func removeAccessToken(for endpoint: Endpoint? = nil) -> Bool {
		guard let key = endpoint?.accessTokenStrategy.storingLabel ?? endpoint?.typeIdentifier ?? AccessTokenStrategy.global.storingLabel else {
			return false
		}
		
		if !storeTokensInKeychain {
			guard Array(accessTokens.keys).contains(key) else { return false }
			accessTokens.removeValue(forKey: key)
			return true
		}
		
		guard let keychain = CNConfig.keychainInstance else {
			#if DEBUG
			print("Cannot read access token from keychain. Please provide keychain instance using CNConfig.keychainInstance or disable keychain storage by setting CNConfig.storeTokensInKeychain to false!")
			#endif
			return false
		}
		
		do {
			let tokenIsPresent = try keychain.contains("accessToken_\(key)")
			guard tokenIsPresent else { return false }
			try keychain.remove("accessToken_\(key)")
			return true
		} catch {
			#if DEBUG
			print(error.localizedDescription)
			#endif
			return false
		}
	}
}

