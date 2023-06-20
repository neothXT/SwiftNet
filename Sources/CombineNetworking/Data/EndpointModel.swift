//
//  EndpointModel.swift
//
//
//  Created by Maciej Burdzicki on 15/06/2023.
//

import Foundation
import Combine

public protocol EndpointModel {
    var identifier: String { get }
    var defaultAccessTokenStrategy: AccessTokenStrategy { get }
    var defaultHeaders: [String: Any] { get }
    var callbackTask: (() async throws -> AccessTokenConvertible?)? { get }
    var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { get }
}

public extension EndpointModel {
    var defaultAccessTokenStrategy: AccessTokenStrategy {
        if CNConfig.defaultAccessTokenStrategy == .default {
            return .custom("\(type(of: self))".replacingOccurrences(of: ".Type", with: ""))
        }
        return CNConfig.defaultAccessTokenStrategy
    }
    var defaultHeaders: [String: Any] { [:] }
    var callbackTask: (() async throws -> AccessTokenConvertible?)? { nil }
    var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { nil }
}
