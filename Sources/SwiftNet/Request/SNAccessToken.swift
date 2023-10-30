//
//  SNAccessToken.swift
//  SwiftNet
//
//  Created by Maciej Burdzicki on 23/06/2021.
//

import Foundation

public struct SNAccessToken: AccessTokenConvertible {
	public let access_token: String
	public let token_type: String
	public let expires_in: Int?
	public let refresh_token: String?
	public let scope: String?
	
	public init(access_token: String, token_type: String = "", expires_in: Int? = nil, refresh_token: String? = nil, scope: String? = nil) {
		self.access_token = access_token
		self.token_type = token_type
		self.expires_in = expires_in
		self.refresh_token = refresh_token
		self.scope = scope
	}
	
	public func convert() -> SNAccessToken? {
		self
	}
}
