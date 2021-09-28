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
	var requiresAccessToken: Bool { get }
    var headers: [String: Any]? { get }
    var data: EndpointData { get }
	var callbackPublisher: AnyPublisher<CNAccessToken?, Error>? { get }
}

public extension Endpoint {
	var requiresAccessToken: Bool { false }
	var callbackPublisher: AnyPublisher<CNAccessToken?, Error>? { nil }
	
	var identifier: String { "\(self)" }
}
