//
//  CNConfig.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 22/06/2021.
//

import Foundation

final public class CNConfig {
	static var pinningModes: PinningMode = PinningMode(rawValue: 0)
	static var certificateNames: [String] = []
	static var SSLKeys: [SecKey]? = nil
}
