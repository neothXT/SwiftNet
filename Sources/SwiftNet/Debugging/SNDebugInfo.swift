//
//  SNDebugInfo.swift
//  SwiftNet
//
//  Created by Maciej Burdzicki on 26/09/2021.
//

import Foundation
import os.log

public enum SNDebugInfoLogMode {
	case start, stop, message
}

fileprivate func logMessage(_ message: String) {
	if #available(iOS 14.0, macOS 11.0, *) {
		   let logger = Logger(subsystem: "com.neothxt.SwiftNet", category: "Network")
		   logger.info("\(message)")
	   } else {
		   #if DEBUG
		   print(message)
		   #endif
	   }
   }

public class SNDebugInfo {
	private static var loggers: [String: SNLogger] = [:]
	
	private init() {}
	
	@discardableResult
	public static func createLogger(for endpoint: Endpoint) -> SNLogger? {
		loggers[endpoint.typeIdentifier] = SNLogger(for: endpoint)
		return loggers[endpoint.typeIdentifier]
	}
	
	public static func getLogger(for endpoint: Endpoint) -> SNLogger? {
		if !Array(loggers.keys).contains(endpoint.typeIdentifier) {
			logMessage("Logger for \(endpoint.typeIdentifier) was not found!")
		}
		
		return loggers[endpoint.typeIdentifier]
	}
}

public class SNLogger {
	private let endpoint: Endpoint
	private var timestamp: Date = Date()
	
	fileprivate init(for endpoint: Endpoint) {
		self.endpoint = endpoint
	}
	
	public func log(_ message: String? = nil,
			 mode: SNDebugInfoLogMode = .start,
			 file: String = #file) {
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
		var output = "\n[\(fileString)][\(endpoint.typeIdentifier)][\(endpoint.method.rawValue.uppercased())]\n\(modeString): \(endpoint.fullURL())\n"
		
		if let message = message {
			output += "\(message)"
			if timeString == "" {
				output += "\n"
			}
		}
		
		if timeString != "" {
			output += "\(timeString)\n"
		}
		
		logMessage(output)
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
			
		case .queryString(let params):
			guard let requestURL = URL(string: url) else { return url }
			url = "\(requestURL)?\(params)"
			
		default:
			break
		}
		
		return url
	}
}
