//
//  CNProvider.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine
import KeychainAccess

public typealias EmptyArrayResponse = [String?]

@available(macOS 10.15, *)
public class CNProvider<T: Endpoint> {
	private var didRetry = false
	
	public init() {}
	
	public func publisher<U: Decodable>(for endpoint: T,
										responseType: U.Type,
										retries: Int = 0,
										expectedStatusCodes: [Int] = [200, 201, 204],
										ignorePinning: Bool = false,
										receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error>? {
		CNDebugInfo.createLogger(for: endpoint)
		return prepPublisher(for: endpoint, ignorePinning: ignorePinning)?
			.flatMap { [weak self] output -> AnyPublisher<Data, Error> in
				guard let response = output.response as? HTTPURLResponse else {
					CNDebugInfo.getLogger(for: endpoint)?.log(CNError.failedToMapResponse.localizedDescription, mode: .stop)
					CNDebugInfo.deleteLoger(for: endpoint)
					return Fail(error: CNError.failedToMapResponse).eraseToAnyPublisher()
				}
				
				if response.statusCode == 401 && !(self?.didRetry ?? true), let publisher = endpoint.refreshTokenPublisher ?? endpoint.callbackPublisher {
					self?.didRetry = true
					return publisher.flatMap { [weak self] token -> AnyPublisher<Data, Error> in
						guard let token = token else {
							return Fail(error: CNError.authenticationFailed).eraseToAnyPublisher()
						}
						CNConfig.setAccessToken(token, for: endpoint)
						return self?.prepPublisher(for: endpoint, ignorePinning: ignorePinning)?.map(\.data).eraseToAnyPublisher() ?? Fail(error: CNError.authenticationFailed).eraseToAnyPublisher()
					}.eraseToAnyPublisher()
				} else if response.statusCode == 401 {
					self?.didRetry = false
					CNDebugInfo.getLogger(for: endpoint)?.log(CNError.authenticationFailed.localizedDescription, mode: .stop)
					CNDebugInfo.deleteLoger(for: endpoint)
					return Fail(error: CNError.authenticationFailed).eraseToAnyPublisher()
				}
				
				guard expectedStatusCodes.contains(response.statusCode) else {
					let error = CNErrorResponse(statusCode: response.statusCode,
												localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
												url: response.url,
												mimeType: response.mimeType,
												data: output.data)
					CNDebugInfo.getLogger(for: endpoint)?.log(CNError.unexpectedResponse(error).localizedDescription, mode: .stop)
					CNDebugInfo.deleteLoger(for: endpoint)
					return Fail(error: CNError.unexpectedResponse(error)).eraseToAnyPublisher()
				}
				
				guard output.data.count > 0 else {
					return Fail(error: CNError.emptyResponse).eraseToAnyPublisher()
				}
				
				CNDebugInfo.getLogger(for: endpoint)?.log("Success", mode: .stop)
				return Result.success(output.data).publisher.eraseToAnyPublisher()
			}
			.decode(type: U.self, decoder: endpoint.jsonDecoder)
			.retry(retries)
			.receive(on: queue)
			.eraseToAnyPublisher()
	}

	
	private func prepareRequest(for endpoint: Endpoint) -> URLRequest? {
		guard let url = endpoint.baseURL?.appendingPathComponent(endpoint.path) else { return nil }
		var request = URLRequest(url: url)
		prepareHeadersAndMethod(endpoint: endpoint, request: &request)
		prepareBody(endpointData: endpoint.data, request: &request)
		CNDebugInfo.getLogger(for: endpoint)?.log("\n" + request.cURL(pretty: true), mode: .start)
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
			request.httpBody = try? model.toJsonData()
			
		case .urlEncoded(let params):
			let data = params.reduce([]) { $0 + ["\($1.key)=\($1.value)"] }
				.joined(separator: ",")
				.data(using: .utf8)
			
			request.httpBody = data
			
		case .bodyData(let data):
			request.httpBody = data
			
		case .plain:
			break
		}
	}
	
	private func prepPublisher(for endpoint: T, ignorePinning: Bool) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error>? {
		guard let urlRequest = prepareRequest(for: endpoint) else { return nil }
		
		return CNConfig.getSession(ignorePinning: ignorePinning).dataTaskPublisher(for: urlRequest)
			.mapError { urlError -> Error in
				let error = CNErrorResponse(statusCode: urlError.errorCode,
											localizedString: urlError.localizedDescription,
											url: urlError.failingURL,
											mimeType: nil,
											data: nil)
				return CNError.unexpectedResponse(error)
			}
			.eraseToAnyPublisher()
	}
}

extension CNConfig {
	fileprivate static func accessToken(for endpoint: Endpoint) -> CNAccessToken? {
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.identifier
		guard let data = Keychain(service: key)[data: "accessToken"] else { return nil }
		return try? JSONDecoder().decode(CNAccessToken.self, from: data)
	}
}
