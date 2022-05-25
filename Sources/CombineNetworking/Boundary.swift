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
	
	public init(name: String, contentDisposition: String, contentType: String) {
		self.name = name
		self.contentType = contentType
		self.contentDisposition = contentDisposition
	}
}

public extension Boundary {
	func toData() throws -> Data {
		try JSONEncoder().encode(self)
	}
}
