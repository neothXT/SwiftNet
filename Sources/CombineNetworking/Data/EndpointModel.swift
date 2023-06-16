//
//  EndpointModel.swift
//
//
//  Created by Maciej Burdzicki on 15/06/2023.
//

import Foundation
import Combine

public protocol EndpointModel {
    var defaultAccessTokenStrategy: AccessTokenStrategy { get }
    var defaultHeaders: [String: Any] { get }
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
    var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { nil }
}
