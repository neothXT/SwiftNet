//
//  Endpoint.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import Combine

@available(macOS 10.15, *)
public protocol Endpoint {
	var baseURL: URL? { get }
    var path: String { get }
    var method: RequestMethod { get }
	var requiresAccessToken: Bool { get }
    var headers: [String: Any]? { get }
    var data: EndpointData { get }
	var jsonDecoder: JSONDecoder { get }
	var accessTokenStrategy: AccessTokenStrategy { get }
	var callbackPublisher: AnyPublisher<CNAccessToken?, Error>? { get }
	var refreshTokenPublisher: AnyPublisher<CNAccessToken?, Error>? { get }
}

@available(macOS 10.15, *)
public extension Endpoint {
	var requiresAccessToken: Bool { false }
	var jsonDecoder: JSONDecoder { .init() }
	var accessTokenStrategy: AccessTokenStrategy { CNConfig.defaultAccessTokenStoringStrategy }
	var callbackPublisher: AnyPublisher<CNAccessToken?, Error>? { nil }
	var refreshTokenPublisher: AnyPublisher<CNAccessToken?, Error>? { nil }
	
	var identifier: String { "\(type(of: self))" }
}
