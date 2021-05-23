//
//  Decodable + toJson.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

extension Decodable {
	public static func fromJson(_ data: Data) throws -> Self {
		try JSONDecoder().decode(self, from: data)
	}
}
