//
//  WebSocketConnectionParameters.swift
//  
//
//  Created by Maciej Burdzicki on 19/07/2022.
//

import Foundation

public struct WebSocketConnectionParameters {
	public let url: URL?
	public let protocols: [String]
	public let ignorePinning: Bool
	public let request: URLRequest?
	
	public init(url: URL, protocols: [String], ignorePinning: Bool) {
		self.url = url
		self.protocols = protocols
		self.ignorePinning = ignorePinning
		self.request = nil
	}
	
	public init(request: URLRequest, ignorePinning: Bool) {
		self.url = request.url
		self.protocols = []
		self.ignorePinning = ignorePinning
		self.request = request
	}
}
