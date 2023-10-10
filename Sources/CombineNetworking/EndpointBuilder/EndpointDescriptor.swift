//
//  EndpointDescriptor.swift
//
//
//  Created by Maciej Burdzicki on 06/09/2023.
//

import Foundation
import Combine

public struct EndpointDescriptor {
    public var urlValues: [URLValue]
    public var headers: [String: Any]?
    public var data: EndpointData?
    public var mock: Codable?
    public var accessTokenStrategy: AccessTokenStrategy?
    public var callbackTask: (() async throws -> AccessTokenConvertible)?
    public var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>?
    public var requiresAccessToken: Bool?
    public var jsonDecoder: JSONDecoder?
    public var boundary: Boundary?
    
    public init(urlValues: [URLValue] = [],
                headers: [String : Any]? = nil,
                data: EndpointData? = nil,
                mock: Codable? = nil,
                accessTokenStrategy: AccessTokenStrategy? = nil,
                callbackTask: (() async throws -> AccessTokenConvertible)? = nil,
                callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? = nil,
                requiresAccessToken: Bool? = nil,
                jsonDecoder: JSONDecoder? = nil,
                boundary: Boundary? = nil) {
        self.urlValues = urlValues
        self.headers = headers
        self.data = data
        self.mock = mock
        self.accessTokenStrategy = accessTokenStrategy
        self.callbackTask = callbackTask
        self.callbackPublisher = callbackPublisher
        self.requiresAccessToken = requiresAccessToken
        self.jsonDecoder = jsonDecoder
        self.boundary = boundary
    }
}

public struct URLValue {
    public var key: String
    public var value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
