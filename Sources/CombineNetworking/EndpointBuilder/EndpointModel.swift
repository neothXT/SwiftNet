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
    var callbackTask: (() async throws -> AccessTokenConvertible)? { get }
}

public extension EndpointModel {
    var defaultAccessTokenStrategy: AccessTokenStrategy { CNConfig.defaultAccessTokenStrategy }
    var defaultHeaders: [String: Any] { [:] }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { nil }
}
