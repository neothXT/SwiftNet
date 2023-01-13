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
	
	/// Saves global Access Token
	public static func setGlobalAccessToken(_ token: CNAccessToken?) {
		guard let key = AccessTokenStrategy.global.storingLabel else { return }
		setAccessToken(token, for: key)
	}
	
	/// Saves new Access Token for specific storing label
	public static func setAccessToken(_ token: CNAccessToken?, for storingLabel: String) {
		guard let token = token else { return }
		guard storeTokensInKeychain else {
			accessTokens[storingLabel] = token
			return
		}
		
		guard let keychain = CNConfig.keychainInstance else {
			#if DEBUG
			print("Cannot store access token in keychain. Please provide keychain instance using CNConfig.keychainInstance or disable keychain storage by setting CNConfig.storeTokensInKeychain to false!")
			#endif
			return
		}
		
		keychain[data: "accessToken_\(storingLabel)"] = try? token.toJsonData()
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
	
	/// Returns global Access Token if present
	public static func globalAccessToken() -> CNAccessToken? {
		guard let key = AccessTokenStrategy.global.storingLabel else { return nil }
		return accessToken(for: key)
	}
	
	/// Returns Access Token for specific storing label if present
	public static func accessToken(for storingLabel: String) -> CNAccessToken? {
		guard storeTokensInKeychain else {
			return accessTokens[storingLabel]
		}
		
		guard let keychain = CNConfig.keychainInstance else {
			#if DEBUG
			print("Cannot read access token from keychain. Please provide keychain instance using CNConfig.keychainInstance or disable keychain storage by setting CNConfig.storeTokensInKeychain to false!")
			#endif
			return nil
		}
		
		guard let data = keychain[data: "accessToken_\(storingLabel)"] else { return nil }
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
	
	/// Removes global Access Token if present
	@discardableResult
	public static func removeGlobalAccessToken() -> Bool {
		guard let key = AccessTokenStrategy.global.storingLabel else { return false }
		return removeAccessToken(for: key)
	}
	
	/// Removes Access Token for specific storing label if present
	@discardableResult
	public static func removeAccessToken(for storingLabel: String) -> Bool {
		if !storeTokensInKeychain {
			guard Array(accessTokens.keys).contains(storingLabel) else { return false }
			accessTokens.removeValue(forKey: storingLabel)
			return true
		}
		
		guard let keychain = CNConfig.keychainInstance else {
			#if DEBUG
			print("Cannot read access token from keychain. Please provide keychain instance using CNConfig.keychainInstance or disable keychain storage by setting CNConfig.storeTokensInKeychain to false!")
			#endif
			return false
		}
		
		do {
			let tokenIsPresent = try keychain.contains("accessToken_\(storingLabel)")
			guard tokenIsPresent else { return false }
			try keychain.remove("accessToken_\(storingLabel)")
			return true
		} catch {
			#if DEBUG
			print(error.localizedDescription)
			#endif
			return false
		}
	}
}