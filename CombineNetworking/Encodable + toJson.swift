//
//  Encodable + toJson.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

extension Encodable {
	public func toJson() throws -> Data {
		try JSONEncoder().encode(self)
	}
}
