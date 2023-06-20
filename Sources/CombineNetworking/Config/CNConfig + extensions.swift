//
//  CNConfig + extensions.swift
//  
//
//  Created by Maciej Burdzicki on 13/01/2023.
//

import Foundation

extension CNConfig {
	private static var accessTokens: [String: CNAccessToken] = [:]
	
	//MARK: set access token methods
	
	/// Saves new Access Token for a given endpoint
	public static func setAccessToken(_ token: CNAccessToken?, for endpoint: Endpoint) {
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.typeIdentifier
		setAccessToken(token, for: key)
	}
	
	/// Saves new Access Token for a given endpoint type identifier
	public static func setAccessToken<T: Endpoint>(_ token: CNAccessToken?, for endpoint: T.Type) {
		setAccessToken(token, for: endpoint.identifier)
	}
    
    /// Saves new Access Token for a given EndpointModel
    public static func setAccessToken<T: EndpointModel>(_ token: CNAccessToken?, for endpointModel: T) {
        setAccessToken(token, for: endpointModel.identifier)
    }
	
	/// Saves global Access Token
	public static func setGlobalAccessToken(_ token: CNAccessToken?) {
		guard let key = AccessTokenStrategy.global.storingLabel else { return }
		setAccessToken(token, for: key)
	}
	
	/// Saves new Access Token for specific storing label
	public static func setAccessToken(_ token: CNAccessToken?, for storingLabel: String) {
		guard let token = token else { return }
		guard let keychain = CNConfig.keychainInstance else {
			accessTokens[storingLabel] = token
			return
		}
		
		guard let data = try? token.toJsonData() else { return }
		keychain.add(data, forKey: "accessToken_\(storingLabel)")
	}
	
	//MARK: fetch access token methods
	
	/// Returns Access Token stored for a given endpoint if present
	public static func accessToken(for endpoint: Endpoint) -> CNAccessToken? {
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.typeIdentifier
		return accessToken(for: key)
	}
	
	/// Returns Access Token stored for a given endpoint type identifier if present
	public static func accessToken<T: Endpoint>(for endpoint: T.Type) -> CNAccessToken? {
		accessToken(for: endpoint.identifier)
	}
    
    /// Returns Access Token stored for a given EndpointModel  identifier if present
    public static func accessToken<T: EndpointModel>(for endpointModel: T) -> CNAccessToken? {
        accessToken(for: endpointModel.identifier)
    }
	
	/// Returns global Access Token if present
	public static func globalAccessToken() -> CNAccessToken? {
		guard let key = AccessTokenStrategy.global.storingLabel else { return nil }
		return accessToken(for: key)
	}
	
	/// Returns Access Token for specific storing label if present
	public static func accessToken(for storingLabel: String) -> CNAccessToken? {
		guard let keychain = CNConfig.keychainInstance else {
			return accessTokens[storingLabel]
		}
		
		guard let data = keychain.fetch(key: "accessToken_\(storingLabel)") else { return nil }
//		guard let data = keychain[data: "accessToken_\(storingLabel)"] else { return nil }
		return try? JSONDecoder().decode(CNAccessToken.self, from: data)
	}
	
	//MARK: remove access token methods
	
	/// Removes stored Access Token for a given endpoint if present
	@discardableResult
	public static func removeAccessToken(for endpoint: Endpoint) -> Bool {
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.typeIdentifier
		return removeAccessToken(for: key)
	}
	
	/// Removes Access Token stored for a given endpoint type identifier if present
	@discardableResult
	public static func removeAccessToken<T: Endpoint>(for endpoint: T.Type) -> Bool {
		removeAccessToken(for: endpoint.identifier)
	}
    
    /// Removes Access Token stored for a given EndpointModel  identifier if present
    @discardableResult
    public static func removeAccessToken<T: EndpointModel>(for endpointModel: T) -> Bool {
        removeAccessToken(for: endpointModel.identifier)
    }
	
	/// Removes global Access Token if present
	@discardableResult
	public static func removeGlobalAccessToken() -> Bool {
		guard let key = AccessTokenStrategy.global.storingLabel else { return false }
		return removeAccessToken(for: key)
	}
	
	/// Removes Access Token for specific storing label if present
	@discardableResult
	public static func removeAccessToken(for storingLabel: String) -> Bool {
		guard let keychain = CNConfig.keychainInstance else {
			guard Array(accessTokens.keys).contains(storingLabel) else { return false }
			accessTokens.removeValue(forKey: storingLabel)
			return true
		}
		
		let key = "accessToken_\(storingLabel)"
		guard keychain.contains(key: key) else { return false }
		keychain.delete(forKey: key)
		return true
	}
}
