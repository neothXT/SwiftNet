//
//  BridgingEndpoint.swift
//
//
//  Created by Maciej Burdzicki on 15/06/2023.
//

import Foundation
import Combine

public enum BridgingEndpoint<T: Codable & Equatable>: Endpoint {
    case custom(EndpointBuilder<T>)
    
    public var baseURL: URL? {
        guard case .custom(let request) = self else { return nil }
        return request.url
    }
    
    public var path: String {
        ""
    }
    
    public var method: RequestMethod {
        guard case .custom(let request) = self else { return .get }
        return RequestMethod(rawValue: request.method) ?? .get
    }
    
    public var headers: [String : Any]? {
        guard case .custom(let request) = self else { return nil }
        return request.headers
    }
    
    public var data: EndpointData {
        guard case .custom(let request) = self else { return .plain }
        return request.data
    }
    
    public var requiresAccessToken: Bool {
        guard case .custom(let request) = self else { return false }
        return request.requiresAccessToken
    }
    
    public var jsonDecoder: JSONDecoder {
        guard case .custom(let request) = self else { return CNConfig.defaultJSONDecoder }
        return request.jsonDecoder
    }
    
    public var accessTokenStrategy: AccessTokenStrategy {
        guard case .custom(let request) = self else { return CNConfig.defaultAccessTokenStrategy }
        return request.accessTokenStrategy
    }
    
    public var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? {
        guard case .custom(let request) = self else { return nil }
        return request.callbackPublisher
    }
    
    public var boundary: Boundary? {
        guard case .custom(let request) = self else { return nil }
        return request.boundary
    }
    
    public var mockedData: Codable? {
        guard case .custom(let request) = self else { return nil }
        return request.mock
    }
}
