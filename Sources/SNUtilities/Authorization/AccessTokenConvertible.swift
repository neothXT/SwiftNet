//
//  AccessTokenConvertible.swift
//  
//
//  Created by Maciej Burdzicki on 22/03/2022.
//

import Foundation

public protocol AccessTokenConvertible: Codable {
    
	/// Converts object to SNAccessToken
	func convert() -> SNAccessToken?
}
