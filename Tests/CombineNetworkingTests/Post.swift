//
//  Post.swift
//  CombineNetworkingTests
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

struct Post: Codable, Equatable {
	let userId: Int
	let id: Int?
	let title: String
	let body: String
}
