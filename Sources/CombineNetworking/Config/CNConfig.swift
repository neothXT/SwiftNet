//
//  File.swift
//  
//
//  Created by Maciej Burdzicki on 13/03/2022.
//

import Foundation
import Combine

public class CNConfig {
	public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
	public static var sitesExcludedFromPinning: [String] = []
	public static var defaultJSONDecoder: JSONDecoder = .init()
	public static var defaultAccessTokenStrategy: AccessTokenStrategy = .default
	public static var keychainInstance: CNKeychain?
	
	private init() {}
	
	static func getSession(ignorePinning: Bool = false) -> URLSession {
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .utility
		
		if ignorePinning || pinningModes.rawValue == 0 {
			return URLSession(configuration: .default,
							  delegate: CNSimpleSessionDelegate(),
							  delegateQueue: operationQueue)
		}
		
		let delegate = CNSessionDelegate(mode: pinningModes, excludedSites: sitesExcludedFromPinning)
		
		return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
	}
}
