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
	var boundary: Boundary? { get }
    var data: EndpointData { get }
	var jsonDecoder: JSONDecoder { get }
	var accessTokenStrategy: AccessTokenStrategy { get }
	var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { get }
}

@available(macOS 10.15, *)
public extension Endpoint {
	var requiresAccessToken: Bool { false }
	var jsonDecoder: JSONDecoder { CNConfig.defaultJSONDecoder }
	var accessTokenStrategy: AccessTokenStrategy { CNConfig.defaultAccessTokenStrategy }
	var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { nil }
	var boundary: Boundary? { nil }
	
	var typeIdentifier: String { "\(type(of: self))" }
	var caseIdentifier: String { String(String(reflecting: self).split(separator: "(").first ?? "\(self)") }
}
