//
//  Todo.swift
//  SwiftNetTests
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

struct Todo: Codable, Identifiable, Equatable {
	let userId: Int
	let id: Int?
	let title: String
	let completed: Bool
}
