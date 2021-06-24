//
//  CNAccessToken.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/06/2021.
//

import Foundation

public struct CNAccessToken: Codable {
	let accessToken: String
	let tokenType: String
	let expiresIn: Int?
	let refreshToken: String?
	let scope: String?
}
