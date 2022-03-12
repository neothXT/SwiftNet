//
//  CNAccessToken.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/06/2021.
//

import Foundation

public struct CNAccessToken: Codable {
	let access_token: String
	let token_type: String
	let expires_in: Int?
	let refresh_token: String?
	let scope: String?
	
	public init(access_token: String, token_type: String, expires_in: Int?, refresh_token: String?, scope: String?) {
		self.access_token = access_token
		self.token_type = token_type
		self.expires_in = expires_in
		self.refresh_token = refresh_token
		self.scope = scope
	}
}
