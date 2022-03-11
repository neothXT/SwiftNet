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
}
