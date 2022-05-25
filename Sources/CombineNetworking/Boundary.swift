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
	func addTo(data: inout Data) {
		guard let nameData = "--\(name)".data(using: .utf8),
			  let contentDispData = "Content-Disposition: \(contentDisposition)".data(using: .utf8),
			  let contentTypeData = "Content-Type: \(contentType)".data(using: .utf8) else {
			return
		}
		
		data.append(nameData)
		data.append(contentDispData)
		data.append(contentTypeData)
	}
}
