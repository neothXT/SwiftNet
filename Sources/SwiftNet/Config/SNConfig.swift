//
//  SNConfig.swift
//  
//
//  Created by Maciej Burdzicki on 13/03/2022.
//

import Foundation
import Combine

public class SNConfig {
	public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
	public static var sitesExcludedFromPinning: [String] = []
	public static var defaultJSONDecoder: JSONDecoder = .init()
	public static var defaultAccessTokenStrategy: AccessTokenStrategy = .global
	public static var keychainInstance: Keychain?
    public static var accessTokenStorage: AccessTokenStorage = SNStorage()
    public static var accessTokenErrorCodes: [Int] = [401]
	
	private init() {}
	
	static func getSession(ignorePinning: Bool = false) -> URLSession {
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .utility
		
		if ignorePinning || pinningModes.rawValue == 0 {
			return URLSession(configuration: .default,
							  delegate: SNSimpleSessionDelegate(),
							  delegateQueue: operationQueue)
		}
		
		let delegate = SNSessionDelegate(mode: pinningModes, excludedSites: sitesExcludedFromPinning)
		
		return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
	}
}
