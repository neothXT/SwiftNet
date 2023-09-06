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
	var mockedData: Codable? { get }
    var data: EndpointData { get }
	var jsonDecoder: JSONDecoder { get }
	var accessTokenStrategy: AccessTokenStrategy { get }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { get }
	var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { get }
    
    var typeIdentifier: String { get }
    var caseIdentifier: String { get }
    static var identifier: String { get }
}

@available(macOS 10.15, *)
public extension Endpoint {
	var requiresAccessToken: Bool { false }
	var jsonDecoder: JSONDecoder { CNConfig.defaultJSONDecoder }
	var accessTokenStrategy: AccessTokenStrategy { CNConfig.defaultAccessTokenStrategy }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { nil }
	var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { nil } // wywalić to i zastąpić samym taskiem
	var boundary: Boundary? { nil }
	var mockedData: Codable? { nil }
	
	var typeIdentifier: String { Self.identifier }
	var caseIdentifier: String { String(String(reflecting: self).split(separator: "(").first ?? "\(self)") }
	static var identifier: String { "\(type(of: self))".replacingOccurrences(of: ".Type", with: "") }
}
