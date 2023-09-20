//
//  EndpointBuilder.swift
//
//
//  Created by Maciej Burdzicki on 15/06/2023.
//

import Foundation
import Combine

public protocol EndpointBuilderAbstract {
    associatedtype T: Codable & Equatable
    
    var url: String { get }
    var method: String { get }
    var headers: [String: Any] { get }
    var data: EndpointData { get }
    var mock: Codable? { get }
    var accessTokenStrategy: AccessTokenStrategy { get }
    var callbackTask: (() async throws -> AccessTokenConvertible)? { get }
    var requiresAccessToken: Bool { get }
    var jsonDecoder: JSONDecoder { get }
    var boundary: Boundary? { get }
    var provider: CNProvider<BridgingEndpoint<T>> { get }
    var identifier: String { get }
    
    func setup(with descriptor: EndpointDescriptor) -> Self
    func extendUrl(with path: String) -> Self
    func setRequestParams(_ data: EndpointData) -> Self
    func setUrlValue(_ value: String, forKey key: String) -> Self
    func setRequiresToken(_ value: Bool) -> Self
    func setCallbackTask(_ callback: @escaping () async throws -> AccessTokenConvertible) -> Self
    func mockResponse(with model: Codable) -> Self
    func using(provider: CNProvider<BridgingEndpoint<T>>) -> Self
    func setBoundary(_ boundary: Boundary) -> Self
    func setDecoder(_ decoder: JSONDecoder) -> Self
    
    func buildPublisher(expectedStatusCodes: [Int], ignorePinning: Bool, receiveOn queue: DispatchQueue) -> AnyPublisher<T, Error>
    func buildUploadPublisher(ignorePinning: Bool, receiveOn queue: DispatchQueue) -> AnyPublisher<UploadResponse<T>, Error>
    func buildAsyncTask(ignorePinning: Bool) async throws -> T
    func test(failOnFinished: Bool, storeIn store: inout Set<AnyCancellable>, onSuccess: @escaping (T?) -> Void, onFailure: @escaping (Error) -> Void)
    func testRaw(failOnFinished: Bool, storeIn store: inout Set<AnyCancellable>, onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void)
}

public class EndpointBuilder<T: Codable & Equatable>: EndpointBuilderAbstract {
    public fileprivate(set) var url: String
    public fileprivate(set) var method: String = "get"
    public fileprivate(set) var headers: [String: Any] = [:]
    public fileprivate(set) var data: EndpointData = .plain
    public fileprivate(set) var mock: Codable?
    public fileprivate(set) var accessTokenStrategy: AccessTokenStrategy
    public fileprivate(set) var callbackTask: (() async throws -> AccessTokenConvertible)?
    public fileprivate(set) var requiresAccessToken: Bool = false
    public fileprivate(set) var jsonDecoder: JSONDecoder = CNConfig.defaultJSONDecoder
    public fileprivate(set) var boundary: Boundary?
    public fileprivate(set) var provider: CNProvider<BridgingEndpoint<T>> = .init()
    public fileprivate(set) var identifier: String

    public init(
        url: String,
        method: String,
        headers: [String : Any],
        accessTokenStrategy: AccessTokenStrategy,
        callbackTask: (() async throws -> AccessTokenConvertible)? = nil,
        identifier: String) {
            self.url = url
            self.method = method
            self.headers = headers
            self.accessTokenStrategy = accessTokenStrategy
            self.callbackTask = callbackTask
            self.identifier = identifier
    }
    
    /// Configures endpoint according to data provided by descriptor
    public func setup(with descriptor: EndpointDescriptor) -> Self {
        descriptor.urlValues.forEach { self.url = self.url.replacingOccurrences(of: "#{\($0.key)}#", with: $0.value) }
        method = descriptor.method?.rawValue ?? method
        headers = descriptor.headers ?? headers
        data = descriptor.data ?? data
        mock = descriptor.mock ?? mock
        accessTokenStrategy = descriptor.accessTokenStrategy ?? accessTokenStrategy
        callbackTask = descriptor.callbackTask ?? callbackTask
        requiresAccessToken = descriptor.requiresAccessToken ?? requiresAccessToken
        jsonDecoder = descriptor.jsonDecoder ?? jsonDecoder
        boundary = descriptor.boundary ?? boundary
        return self
    }
    
    /// Extends request's url with provided path
    public func extendUrl(with path: String) -> Self {
        url = url + path
        return self
    }
    
    /// Inserts provided params into a request
    public func setRequestParams(_ data: EndpointData) -> Self {
        self.data = data
        return self
    }
    
    /// Sets value for a given #{variable}# in url string
    public func setUrlValue(_ value: String, forKey key: String) -> Self {
        url = url.replacingOccurrences(of: "#{\(key)}#", with: value)
        return self
    }
    
    /// Assigns value to requiresAccessToken flag
    public func setRequiresToken(_ value: Bool) -> Self {
        requiresAccessToken = value
        return self
    }
    
    /// Provides callback task for a request
    public func setCallbackTask(_ callback: @escaping () async throws -> AccessTokenConvertible) -> Self {
        callbackTask = callback
        return self
    }
    
    /// Mocks request's response
    public func mockResponse(with model: Codable) -> Self {
        mock = model
        return self
    }
    
    /// Sets CNProvider for a request
    public func using(provider: CNProvider<BridgingEndpoint<T>>) -> Self {
        self.provider = provider
        return self
    }
    
    /// Sets boundary for a request
    public func setBoundary(_ boundary: Boundary) -> Self {
        self.boundary = boundary
        return self
    }
    
    /// Sets JSON decoder
    public func setDecoder(_ decoder: JSONDecoder) -> Self {
        self.jsonDecoder = decoder
        return self
    }
    
    /// Generates AnyPublisher
    public func buildPublisher(
        expectedStatusCodes: [Int] = [200, 201, 204],
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<T, Error> {
        provider.publisher(for: .custom(self),
                           responseType: T.self,
                           decoder: jsonDecoder,
                           expectedStatusCodes: expectedStatusCodes,
                           ignorePinning: ignorePinning,
                           receiveOn: queue)
    }
    
    /// Generates AnyPublisher for upload request
    public func buildUploadPublisher(
        ignorePinning: Bool = false,
        receiveOn queue: DispatchQueue = .main
    ) -> AnyPublisher<UploadResponse<T>, Error> {
        provider.uploadPublisher(for: .custom(self),
                                 responseType: T.self,
                                 decoder: jsonDecoder,
                                 ignorePinning: ignorePinning,
                                 receiveOn: queue)
    }
    
    /// Generates async/await task
    public func buildAsyncTask(ignorePinning: Bool = false) async throws -> T {
        try await provider.task(for: .custom(self), responseType: T.self, decoder: jsonDecoder)
    }
    
    /// Tests a request and typechecks the response
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
    
    /// Tests a request without response typecheck
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
