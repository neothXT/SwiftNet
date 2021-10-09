//
//  CNDebugInfo.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 26/09/2021.
//

import Foundation

public enum CNDebugInfoLogMode {
	case start, stop
}

public class CNDebugInfo {
	private let endpoint: Endpoint
	private var timestamp: Date = Date()
	
	init(for endpoint: Endpoint) {
		self.endpoint = endpoint
	}
	
	func log(_ message: String,
			 mode: CNDebugInfoLogMode = .start,
			 file: String = #file) {
		#if DEBUG
		var modeString = "@"
		var timeString = ""
		switch mode {
		case .start:
			timestamp = Date()
			modeString += "Sent"
		case .stop:
			modeString += "Received"
			let timeValue = Double(Date().timeIntervalSince(timestamp)) * 1000
			timeString = " (" + String(format: "%.3f", timeValue) + " milliseconds)"
		}
		
		var fileString = file
		
		if let subString = file.split(separator: "/").last {
			fileString = String(subString)
		}
		let output = "\n[\(fileString)][\(endpoint.identifier)][\(endpoint.method.rawValue.uppercased())]\n\(modeString): \(endpoint.fullURL())\n\(message)\(timeString)\n"
		print(output)
		#endif
	}
}

extension Endpoint {
	fileprivate func fullURL() -> String {
		var url = baseURL?.absoluteString ?? (path.hasPrefix("/") ? "<UNKNOWN>" : "<UNKNOWN>/")
		
		url += path
		
		switch data {
		case .queryParams(let params):
			guard let requestURL = URL(string: url) else { return url }
			var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: true)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
			url = urlComponents?.url?.absoluteString ?? url
			
		default:
			break
		}
		
		return url
	}
}
