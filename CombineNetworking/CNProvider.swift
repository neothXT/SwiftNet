//
//  CNProvider.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine


public class CNProvider<T: Endpoint> {
	public init() {}
	
	public func publisher<U: Decodable>(for endpoint: T,
										retries: Int = 0,
										expectedStatusCodes: [Int] = [200, 201, 204],
										decoder: JSONDecoder = JSONDecoder(),
										receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error>? {
		
		guard let urlRequest = prepareRequest(for: endpoint) else { return nil }
		return URLSession.shared.dataTaskPublisher(for: urlRequest)
			.retry(retries)
			.tryMap { output in
				guard let response = output.response as? HTTPURLResponse else {
					throw CNError.failedToMapResponse
				}
				
				guard expectedStatusCodes.contains(response.statusCode) else {
					let error = CNErrorResponse(statusCode: response.statusCode,
												localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
												url: response.url,
												mimeType: response.mimeType)
					throw CNError.unexpectedResponse(error)
				}
				
				return output.data
			}
			.decode(type: U.self, decoder: decoder)
			.receive(on: queue)
			.eraseToAnyPublisher()
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
