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
	
	public func publisher<U: Decodable>(for request: T, receiveOn queue: DispatchQueue = .main) -> AnyPublisher<U, Error>? {
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
			let jsonModel = try? JSONSerialization.data(withJSONObject: model, options: [])
			urlRequest.httpBody = try? JSONEncoder().encode(jsonModel)
		case .plain:
			break
		}
		
		return URLSession.shared.dataTaskPublisher(for: urlRequest)
			.map(\.data)
			.decode(type: U.self, decoder: JSONDecoder())
			.receive(on: queue)
			.eraseToAnyPublisher()
	}
}
