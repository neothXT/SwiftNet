//
//  CNError.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

public enum CNError: Error {
	case failedToMapResponse, badResponse(CNErrorResponse)
}

public struct CNErrorResponse {
	let statusCode: Int
	let localizedString: String
	let url: URL?
	let mimeType: String?
}
