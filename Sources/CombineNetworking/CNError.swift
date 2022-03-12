//
//  CNError.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

public enum CNError: Error {
	case failedToMapResponse, unexpectedResponse(CNErrorResponse), authenticationFailed, notConnected
	
	public var detailedResponse: CNErrorResponse? {
		switch self {
		case .unexpectedResponse(let response):
			return response
		default:
			return nil
		}
	}
}

public struct CNErrorResponse {
	public let statusCode: Int
	public let localizedString: String
	public let url: URL?
	public let mimeType: String?
	public let data: Data?
	
	public init(statusCode: Int, localizedString: String, url: URL?, mimeType: String?, data: Data?) {
		self.statusCode = statusCode
		self.localizedString = localizedString
		self.url = url
		self.mimeType = mimeType
		self.data = data
	}
	
}
