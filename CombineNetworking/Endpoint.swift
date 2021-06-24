//
//  Endpoint.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine

public protocol Endpoint {
	var baseURL: URL? { get }
    var path: String { get }
    var method: RequestMethod { get }
    var headers: [String: Any]? { get }
    var data: EndpointData { get }
	
	var authenticationPublisher: AnyPublisher<CNAccessToken?, Error>? { get }
}

extension Endpoint {
	var authenticationPublisher: AnyPublisher<CNAccessToken?, Error>? { nil }
}
