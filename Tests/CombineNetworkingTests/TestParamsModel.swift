//
//  TestParamsModel.swift
//  TestParamsModel
//
//  Created by Maciej Burdzicki on 07/09/2022.
//

import Foundation

struct TestParamsModel: Codable {
	let name: String
	let lastname: String
	let age: Int?
}

struct TestParamsModelWithArray: Codable {
	let name: String
	let lastname: String
	let age: Int?
	let array: [String]
}

struct TestParamsModelWithDict: Codable {
	let name: String
	let lastname: String
	let age: Int?
	let dict: [String: String]
}

struct TestParamsModelWithEnum: Codable {
	let name: String
	let lastname: String
	let age: Int?
	let sex: Sex?
	
	enum Sex: String, Codable {
		case male, female
	}
}
