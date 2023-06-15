//
//  EndpointBuilder.swift
//
//
//  Created by Maciej Burdzicki on 15/06/2023.
//

import Foundation
import Combine

public class EndpointBuilder<T: Codable & Equatable> {
    fileprivate(set) var url: URL?
    fileprivate(set) var method: String = "get"
    fileprivate(set) var headers: [String: Any] = [:]
    fileprivate(set) var data: EndpointData = .plain
    fileprivate(set) var mock: Codable?
    fileprivate(set) var accessTokenStrategy: AccessTokenStrategy = CNConfig.defaultAccessTokenStrategy
    fileprivate(set) var callbackTask: (() async throws -> AccessTokenConvertible)? = nil
    fileprivate(set) var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>?
    fileprivate(set) var requiresAccessToken: Bool = false
    fileprivate(set) var jsonDecoder: JSONDecoder = CNConfig.defaultJSONDecoder
    fileprivate(set) var boundary: Boundary?
    fileprivate(set) var provider: CNProvider<BridgingEndpoint<T>> = .init()

    public init(
        url: String,
        method: String,
        headers: [String : Any],
        accessTokenStrategy: AccessTokenStrategy,
        callbackTask: (() -> AccessTokenConvertible)? = nil,
        callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? = nil) {
            self.url = URL(string: url)
            self.method = method
            self.headers = headers
            self.accessTokenStrategy = accessTokenStrategy
            self.callbackTask = callbackTask
            self.callbackPublisher = callbackPublisher
    }
    
    public func extendUrl(with path: String) -> Self {
        url = url?.appendingPathComponent(path)
        return self
    }
    
    public func setRequestParams(_ data: EndpointData) -> Self {
        self.data = data
        return self
    }
    
    public func setAsyncCallback(_ callback: @escaping () async throws -> AccessTokenConvertible) -> Self {
        callbackTask = callback
        return self
    }
    
    public func mockResponse(with model: Codable) -> Self {
        mock = model
        return self
    }
    
    public func using(provider: CNProvider<BridgingEndpoint<T>>) -> Self {
        self.provider = provider
        return self
    }
    
    public func build(
        retries: Int = 0,
        expectedStatusCodes: [Int] = [200, 201, 204],
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<T, Error> {
        provider.publisher(for: .custom(self),
                           responseType: T.self,
                           retries: retries,
                           expectedStatusCodes: expectedStatusCodes,
                           ignorePinning: ignorePinning,
                           receiveOn: queue)
    }
    
    public func buildForUpload(
        retries: Int = 0,
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<UploadResponse<T>, Error> {
        provider.uploadPublisher(for: .custom(self),
                                 responseType: T.self,
                                 retries: retries,
                                 ignorePinning: ignorePinning,
                                 receiveOn: queue)
    }
    
    public func buildAsync(ignorePinning: Bool = false) async throws -> T {
        try await provider.task(for: .custom(self), responseType: T.self, callbackTask: callbackTask)
    }
    
    public func test(
        failOnFinished: Bool = true,
        storeIn store: inout Set<AnyCancellable>,
        onSuccess: @escaping (T?) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        provider.test(.custom(self),
                      responseType: T.self,
                      usingMocks: mock != nil,
                      storeIn: &store,
                      failOnFinishedReceived: failOnFinished,
                      onSuccess: onSuccess,
                      onFailure: onFailure)
    }
    
    public func testRaw(
        failOnFinished: Bool = true,
        storeIn store: inout Set<AnyCancellable>,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        provider.testRaw(.custom(self),
                         usingMocks: mock != nil,
                         storeIn: &store,
                         failOnFinishedReceived: failOnFinished,
                         onSuccess: onSuccess,
                         onFailure: onFailure)
    }
    
}
