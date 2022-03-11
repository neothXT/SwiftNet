//
//  Todo.swift
//  CombineNetworkingTests
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

struct Todo: Codable, Identifiable {
	let userId: Int
	let id: Int?
	let title: String
	let completed: Bool
}
