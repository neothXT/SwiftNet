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
        return URL(string: request.url)
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
        guard case .custom(let request) = self else { return SNConfig.defaultJSONDecoder }
        return request.jsonDecoder
    }
    
    public var accessTokenStrategy: AccessTokenStrategy {
        guard case .custom(let request) = self else { return SNConfig.defaultAccessTokenStrategy }
        return request.accessTokenStrategy
    }
    
    public var callbackTask: (() async throws -> AccessTokenConvertible)? {
        guard case .custom(let request) = self else { return nil }
        return request.callbackTask
    }
    
    public var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? {
        guard case .custom(let request) = self, let task = request.callbackTask else { return nil }
        
        let publisher: PassthroughSubject<AccessTokenConvertible, Error> = .init()
        
        Task {
            do {
                let token = try await task()
                publisher.send(token)
            } catch {
                publisher.send(completion: .failure(error))
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    public var boundary: Boundary? {
        guard case .custom(let request) = self else { return nil }
        return request.boundary
    }
    
    public var mockedData: Codable? {
        guard case .custom(let request) = self else { return nil }
        return request.mock
    }
    
    public var typeIdentifier: String {
        guard case .custom(let request) = self else { return "\(type(of: self))".replacingOccurrences(of: ".Type", with: "") }
        return request.identifier
    }
}
