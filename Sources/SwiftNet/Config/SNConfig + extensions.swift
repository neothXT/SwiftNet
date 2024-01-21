//
//  SNConfig + extensions.swift
//  
//
//  Created by Maciej Burdzicki on 13/01/2023.
//

import Foundation


extension SNConfig {
	//MARK: set access token methods
	
	/// Saves new Access Token for a given endpoint
	public static func setAccessToken(_ token: SNAccessToken?, for endpoint: Endpoint) {
        setAccessToken(token, for: endpoint.accessTokenStrategy.storingLabel)
	}
    
    /// Saves Access Token stored for a given EndpointModel if present
    public static func setAccessToken<T: EndpointModel>(_ token: SNAccessToken?, for endpointModel: T) {
        setAccessToken(token, for: T.defaultAccessTokenStrategy.storingLabel)
    }
    
    /// Saves new Access Token for a given EndpointBuilder if present
    public static func setAccessToken<D: Decodable, T: EndpointBuilder<D>>(_ token: SNAccessToken?, for endpointBuilder: T) {
        setAccessToken(token, for: endpointBuilder.accessTokenStrategy.storingLabel)
    }
	
	/// Saves global Access Token
	public static func setGlobalAccessToken(_ token: SNAccessToken?) {
		setAccessToken(token, for: AccessTokenStrategy.global.storingLabel)
	}
	
	/// Saves new Access Token for specific storing label
	public static func setAccessToken(_ token: SNAccessToken?, for storingLabel: String) {
        SNConfig.accessTokenStorage.store(token, for: storingLabel)
	}
	
	//MARK: fetch access token methods
    
	/// Returns Access Token stored for a given endpoint if present
	public static func accessToken(for endpoint: Endpoint) -> SNAccessToken? {
		accessToken(for: endpoint.accessTokenStrategy.storingLabel)
	}
    
    /// Returns Access Token stored for a given EndpointModel if present
    public static func accessToken<T: EndpointModel>(for endpointModel: T) -> SNAccessToken? {
        accessToken(for: T.defaultAccessTokenStrategy.storingLabel)
    }
	
    /// Returns Access Token stored for a given EndpointBuilder if present
    public static func accessToken<D: Decodable, T: EndpointBuilder<D>>(for endpointBuilder: T) -> SNAccessToken? {
        accessToken(for: endpointBuilder.accessTokenStrategy.storingLabel)
    }
	
	/// Returns global Access Token if present
	public static func globalAccessToken() -> SNAccessToken? {
		accessToken(for: AccessTokenStrategy.global.storingLabel)
	}
	
	/// Returns Access Token for specific storing label if present
	public static func accessToken(for storingLabel: String) -> SNAccessToken? {
        SNConfig.accessTokenStorage.fetch(for: storingLabel)
	}
	
	//MARK: remove access token methods
	
	/// Removes stored Access Token for a given endpoint if present
	@discardableResult
	public static func removeAccessToken(for endpoint: Endpoint) -> Bool {
		removeAccessToken(for: endpoint.accessTokenStrategy.storingLabel)
	}
    
    /// Removes Access Token stored for a given EndpointModel if present
    @discardableResult
    public static func removeAccessToken<T: EndpointModel>(for endpointModel: T) -> Bool {
        removeAccessToken(for: T.defaultAccessTokenStrategy.storingLabel)
    }
    
    /// Removes Access Token stored for a given EndpointBuilder if present
    @discardableResult
    public static func removeAccessToken<D: Decodable, T: EndpointBuilder<D>>(for endpointBuilder: T) -> Bool {
        removeAccessToken(for: endpointBuilder.accessTokenStrategy.storingLabel)
    }
	
	/// Removes global Access Token if present
	@discardableResult
	public static func removeGlobalAccessToken() -> Bool {
		removeAccessToken(for: AccessTokenStrategy.global.storingLabel)
	}
	
	/// Removes Access Token for specific storing label if present
	@discardableResult
	public static func removeAccessToken(for storingLabel: String) -> Bool {
        SNConfig.accessTokenStorage.delete(for: storingLabel)
	}
}
