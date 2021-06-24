//
//  CNProvider.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine

public class CNConfig {
	static public let shared = CNConfig()
	
	var pinningModes: PinningMode = PinningMode(rawValue: 0)
	var certificateNames: [String] = []
	var SSLKeys: [SecKey]? = nil
	private(set) var accessToken: [String: CNAccessToken] = [:]
	
	private init() {}
	
	fileprivate func setToken(_ token: CNAccessToken?, for endpoint: Endpoint) {
		guard let token = token else { return }
		accessToken[endpoint.identifier] = token
	}
}

public class CNProvider<T: Endpoint> {
	public init() {}
	
	public func publisher<U: Decodable>(for endpoint: T,
										retries: Int = 0,
										expectedStatusCodes: [Int] = [200, 201, 204],
										decoder: JSONDecoder = JSONDecoder(),
										receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error>? {
		
		guard let urlRequest = prepareRequest(for: endpoint) else { return nil }
		return getSession().dataTaskPublisher(for: urlRequest)
			.mapError { urlError -> Error in
				let error = CNErrorResponse(statusCode: urlError.errorCode,
											localizedString: urlError.localizedDescription,
											url: urlError.failingURL,
											mimeType: nil)
				return CNError.unexpectedResponse(error)
			}
			.flatMap { output -> AnyPublisher<Data, Error> in
				guard let response = output.response as? HTTPURLResponse else {
					return Fail(error: CNError.failedToMapResponse).eraseToAnyPublisher()
				}
				
				if response.statusCode == 401, let publisher = endpoint.authenticationPublisher {
					return publisher.flatMap { token -> AnyPublisher<Data, Error> in
						CNConfig.shared.setToken(token, for: endpoint)
						return Fail(error: CNError.authenticationFailed).eraseToAnyPublisher()
					}.eraseToAnyPublisher()
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
			.retry(retries)
			.decode(type: U.self, decoder: decoder)
			.receive(on: queue)
			.eraseToAnyPublisher()
	}
	
	private func getSession() -> URLSession {
		if CNConfig.shared.pinningModes.rawValue == 0 { return .shared }
		
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .utility
		
		let delegate = CNSessionDelegate(mode: CNConfig.shared.pinningModes,
										 certNames: CNConfig.shared.certificateNames,
										 SSLKeys: CNConfig.shared.SSLKeys)
		
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
		request.httpMethod = endpoint.method.rawValue
	}
	
	private func prepareBody(endpointData: EndpointData, request: inout URLRequest) {
		switch endpointData {
		case .queryParams(let params):
			guard let url = request.url else { return }
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
			request.url = urlComponents?.url
		case .dataParams(let params):
			request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
		case .jsonModel(let model):
			request.httpBody = try? model.toJson()
		case .plain:
			break
		}
	}
}

extension Endpoint {
	fileprivate var identifier: String { String(describing: self) }
}
