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
	
	public func publisher<U: Decodable>(for request: T,
										retries: Int = 0,
										expectedStatusCodes: [Int] = [200, 201, 204],
										decoder: JSONDecoder = JSONDecoder(),
										receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error>? {
		let url = request.baseURL.appendingPathComponent(request.path)
		var urlRequest = URLRequest(url: url)
		
		request.headers?.forEach { key, value in
			urlRequest.addValue("\(value)", forHTTPHeaderField: key)
		}
		
		urlRequest.httpMethod = request.method.rawValue
		
		switch request.data {
		case .queryParams(let params):
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
			urlRequest.url = urlComponents?.url
		case .dataParams(let params):
			urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
		case .jsonModel(let model):
			urlRequest.httpBody = try? model.toJson()
		case .plain:
			break
		}
		
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
					throw CNError.badResponse(error)
				}
				
				return output.data
			}
			.decode(type: U.self, decoder: decoder)
			.receive(on: queue)
			.eraseToAnyPublisher()
	}
}
