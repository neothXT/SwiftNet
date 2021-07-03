//
//  CNProvider.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine

public class CNConfig {
	public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
	public static var certificateNames: [String] = []
	public static var SSLKeys: [SecKey]? = nil
	private(set) static var accessToken: [String: CNAccessToken] = [:]
	
	private init() {}
	
	static fileprivate func setToken(_ token: CNAccessToken?, for endpoint: Endpoint) {
		guard let token = token else { return }
		accessToken[endpoint.identifier] = token
	}
}

public class CNProvider<T: Endpoint> {
	public init() {}
	
	public func publisher<U: Decodable>(for endpoint: T,
										responseType: U.Type,
										retries: Int = 0,
										expectedStatusCodes: [Int] = [200, 201, 204],
										decoder: JSONDecoder = JSONDecoder(),
										receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error>? {
		return prepPublisher(for: endpoint)?
			.flatMap { output -> AnyPublisher<Data, Error> in
				guard let response = output.response as? HTTPURLResponse else {
					return Fail(error: CNError.failedToMapResponse).eraseToAnyPublisher()
				}
				
				if response.statusCode == 401, let publisher = endpoint.callbackPublisher {
					return publisher.flatMap { [weak self] token -> AnyPublisher<Data, Error> in
						CNConfig.setToken(token, for: endpoint)
						return self?.prepPublisher(for: endpoint)?.map(\.data).eraseToAnyPublisher() ?? Fail(error: CNError.authenticationFailed).eraseToAnyPublisher()
					}.eraseToAnyPublisher()
				} else if response.statusCode == 401 {
					return Fail(error: CNError.authenticationFailed).eraseToAnyPublisher()
				}
				
				guard expectedStatusCodes.contains(response.statusCode) else {
					let error = CNErrorResponse(statusCode: response.statusCode,
												localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
												url: response.url,
												mimeType: response.mimeType)
					return Fail(error: CNError.unexpectedResponse(error)).eraseToAnyPublisher()
				}
				return Result.success(output.data).publisher.eraseToAnyPublisher()
			}
			.decode(type: U.self, decoder: decoder)
			.retry(retries)
			.receive(on: queue)
			.eraseToAnyPublisher()
	}
	
	private func getSession() -> URLSession {
		if CNConfig.pinningModes.rawValue == 0 { return .shared }
		
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .utility
		
		let delegate = CNSessionDelegate(mode: CNConfig.pinningModes,
										 certNames: CNConfig.certificateNames,
										 SSLKeys: CNConfig.SSLKeys)
		
		return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
	}
	
	private func prepareRequest(for endpoint: Endpoint) -> URLRequest? {
		guard let url = endpoint.baseURL?.appendingPathComponent(endpoint.path) else { return nil }
		var request = URLRequest(url: url)
		prepareHeadersAndMethod(endpoint: endpoint, request: &request)
		prepareBody(endpointData: endpoint.data, request: &request)
		return request
	}
	
	private func prepareHeadersAndMethod(endpoint: Endpoint, request: inout URLRequest) {
		endpoint.headers?.forEach { key, value in
			request.addValue("\(value)", forHTTPHeaderField: key)
		}
		if endpoint.requiresAccessToken {
			let token = CNConfig.accessToken[endpoint.identifier]?.access_token ?? ""
			request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}
		request.httpMethod = endpoint.method.rawValue
	}
	
	private func prepareBody(endpointData: EndpointData, request: inout URLRequest) {
		switch endpointData {
		case .queryParams(let params):
			guard let url = request.url else { return }
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
			request.url = urlComponents?.url
			
		case .bodyParams(let params):
			request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
			
		case .jsonModel(let model):
			request.httpBody = try? model.toJson()
			
		case .urlEncoded(let params):
			let data = params.reduce([]) { $0 + ["\($1.key)=\($1.value)"] }
				.joined(separator: ",")
				.data(using: .utf8)
			
			request.httpBody = data
			
		case .plain:
			break
		}
	}
	
	private func prepPublisher(for endpoint: T) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error>? {
		guard let urlRequest = prepareRequest(for: endpoint) else { return nil }
		
		return getSession().dataTaskPublisher(for: urlRequest)
			.mapError { urlError -> Error in
				let error = CNErrorResponse(statusCode: urlError.errorCode,
											localizedString: urlError.localizedDescription,
											url: urlError.failingURL,
											mimeType: nil)
				return CNError.unexpectedResponse(error)
			}
			.eraseToAnyPublisher()
	}
}

extension Endpoint {
	fileprivate var identifier: String { String(describing: self) }
}
