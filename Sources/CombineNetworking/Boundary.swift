//
//  Boundary.swift
//  
//
//  Created by Maciej Burdzicki on 25/05/2022.
//

import Foundation

public struct Boundary: Codable {
	public let name: String
	public let contentDisposition: String
	public let contentType: String
}

public extension Boundary {
	func toData() throws -> Data {
		try JSONEncoder().encode(self)
	}
}
