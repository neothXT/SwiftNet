//
//  Comment.swift
//  CombineNetworkingTests
//
//  Created by Maciej Burdzicki on 24/05/2021.
//

import Foundation

struct Comment: Codable {
	let postId: Int
	let id: Int?
	let name: String
	let email: String
	let body: String
}
