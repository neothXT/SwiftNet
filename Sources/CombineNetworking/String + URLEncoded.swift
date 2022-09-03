//
//  String + URLEncoded.swift
//  
//
//  Created by Maciej Burdzicki on 03/09/2022.
//

import Foundation

extension String {
	func URLEncoded() -> String {
		addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved) ?? ""
	}
}

extension CharacterSet {
	static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
