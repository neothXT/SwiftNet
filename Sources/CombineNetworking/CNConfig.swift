//
//  File.swift
//  
//
//  Created by Maciej Burdzicki on 13/03/2022.
//

import Foundation
import Combine
import KeychainAccess

public class CNConfig {
	public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
	public static var certificateNames: [String] = []
	public static var SSLKeys: [SecKey]? = nil
	public static var defaultJSONDecoder: JSONDecoder = .init()
	public static var defaultAccessTokenStrategy: AccessTokenStrategy = .default
	public static var storeTokensInKeychain: Bool = true
	public static var keychainInstance: Keychain?
	
	private init() {}
	
	static func getSession(ignorePinning: Bool = false) -> URLSession {
		if ignorePinning || pinningModes.rawValue == 0 { return .shared }
		
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .utility
		
		let delegate = CNSessionDelegate(mode: pinningModes,
										 certNames: certificateNames,
										 SSLKeys: SSLKeys)
		
		return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
	}
}
