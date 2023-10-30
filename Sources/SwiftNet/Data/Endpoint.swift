//
//  Endpoint.swift
//  SwiftNet
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
	var mockedData: Codable? { get }
    var data: EndpointData { get }
	var jsonDecoder: JSONDecoder { get }
	var accessTokenStrategy: AccessTokenStrategy { get }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { get }
	var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { get }
    
    var typeIdentifier: String { get }
}

@available(macOS 10.15, *)
public extension Endpoint {
	var requiresAccessToken: Bool { false }
	var jsonDecoder: JSONDecoder { SNConfig.defaultJSONDecoder }
	var accessTokenStrategy: AccessTokenStrategy { SNConfig.defaultAccessTokenStrategy }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { nil }
	var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { nil }
	var boundary: Boundary? { nil }
	var mockedData: Codable? { nil }
	
	var typeIdentifier: String { "\(type(of: self))".replacingOccurrences(of: ".Type", with: "") }
}
