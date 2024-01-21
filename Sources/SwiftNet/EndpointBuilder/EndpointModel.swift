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
    static var defaultAccessTokenStrategy: AccessTokenStrategy { get }
    static var defaultHeaders: [String: Any] { get }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { get }
}

public extension EndpointModel {
    static var defaultAccessTokenStrategy: AccessTokenStrategy { SNConfig.defaultAccessTokenStrategy }
    static var defaultHeaders: [String: Any] { [:] }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { nil }
}
