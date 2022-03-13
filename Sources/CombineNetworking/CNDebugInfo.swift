//
//  CNDebugInfo.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 26/09/2021.
//

import Foundation

public enum CNDebugInfoLogMode {
	case start, stop, message
}

public class CNDebugInfo {
	private static var loggers: [String: CNLogger] = [:]
	
	private init() {}
	
	@discardableResult
	public static func createLogger(for endpoint: Endpoint) -> CNLogger {
		loggers[endpoint.identifier] = CNLogger(for: endpoint)
		return loggers[endpoint.identifier]!
	}
	
	public static func getLogger(for endpoint: Endpoint) -> CNLogger? {
		#if DEBUG
		if !Array(loggers.keys).contains(endpoint.identifier) {
			print("Logger for \(endpoint.identifier) was not found!")
		}
		#endif
		
		return loggers[endpoint.identifier]
	}
	
	public static func deleteLoger(for endpoint: Endpoint) {
		loggers.removeValue(forKey: endpoint.identifier)
	}
}

public class CNLogger {
	private let endpoint: Endpoint
	private var timestamp: Date = Date()
	
	fileprivate init(for endpoint: Endpoint) {
		self.endpoint = endpoint
	}
	
	public func log(_ message: String? = nil,
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
		case .message:
			modeString += "Message"
		}
		
		var fileString = file
		
		if let subString = file.split(separator: "/").last {
			fileString = String(subString)
		}
		var output = "\n[\(fileString)][\(endpoint.identifier)][\(endpoint.method.rawValue.uppercased())]\n\(modeString): \(endpoint.fullURL())\n"
		
		if let message = message {
			output += "\(message)"
			if timeString == "" {
				output += "\n"
			}
		}
		
		if timeString != "" {
			output += "\(timeString)\n"
		}
		
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
