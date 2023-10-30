//
//  Keychain.swift
//  
//
//  Created by Maciej Burdzicki on 25/04/2023.
//

import Foundation

public class Keychain {
	private let service: String
	
	public init(serviceName: String) {
		service = serviceName
	}
	
	public convenience init() {
		var serviceName = "SwiftNet"
		if let bundleIdentifier = Bundle.main.bundleIdentifier {
			serviceName = bundleIdentifier
		}
		self.init(serviceName: serviceName)
	}
	
	func add(_ item: Data, forKey key: String) {
		let query = [
			kSecAttrService: service as Any,
			kSecAttrAccount: key as Any,
			kSecClass: kSecClassGenericPassword,
			kSecValueData: item
		]
		
		let status = SecItemAdd(query as CFDictionary, nil)
		
		if status == errSecDuplicateItem {
			update(item, forKey: key)
		}
	}
	
	func update(_ item: Data, forKey key: String) {
		let query = [
			kSecAttrService: service as Any,
			kSecAttrAccount: key as Any,
			kSecClass: kSecClassGenericPassword
		]
		
		let attrs = [
			kSecValueData: item
		]
		
		SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
	}
	
	func fetch(key: String) -> Data? {
		let query = [
			kSecAttrService: service as Any,
			kSecAttrAccount: key as Any,
			kSecClass: kSecClassGenericPassword,
			kSecMatchLimit: kSecMatchLimitOne,
			kSecReturnData: kCFBooleanTrue as Any
		]
		
		var item: AnyObject?
		SecItemCopyMatching(query as CFDictionary, &item)
		
		return item as? Data
	}
	
	func delete(forKey key: String) {
		let query = [
			kSecAttrService: service as Any,
			kSecAttrAccount: key as Any,
			kSecClass: kSecClassGenericPassword
		]
		
		SecItemDelete(query as CFDictionary)
	}
	
	func contains(key: String) -> Bool {
		let item = fetch(key: key)
		
		return item != nil
	}
}
