//
//  Post.swift
//  SwiftUITraining
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

struct Post: Codable {
	let userId: Int
	let id: Int?
	let title: String
	let body: String
}
