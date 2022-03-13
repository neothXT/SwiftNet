//
//  File.swift
//  
//
//  Created by Maciej Burdzicki on 13/03/2022.
//

import Foundation
import KeychainAccess

public class CNConfig {
	public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
	public static var certificateNames: [String] = []
	public static var SSLKeys: [SecKey]? = nil
	public static var defaultJSONDecoder: JSONDecoder = .init()
	public static var defaultAccessTokenStoringStrategy: AccessTokenStrategy = .default
	
	private init() {}
	
	public static func setAccessToken(_ token: CNAccessToken?, for endpoint: Endpoint) {
		guard let token = token else { return }
		let key = endpoint.accessTokenStrategy.storingLabel ?? endpoint.identifier
		Keychain(service: key)[data: "accessToken"] = try? token.toJsonData()
	}
	
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
