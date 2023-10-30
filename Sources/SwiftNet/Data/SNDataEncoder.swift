//
//  SNDataEncoder.swift
//  SwiftNet
//
//  Created by Maciej Burdzicki on 07/09/2022.
//

import Foundation

class SNDataEncoder {
	static func encode(_ endpointData: EndpointData, boundary: Boundary?, request: inout URLRequest) {
		switch endpointData {
		case .queryString(let params):
			guard let url = request.url else { return }
			request.url = URL(string: "\(url)?\(params)")
		case .queryParams(let params):
			guard let url = request.url else { return }
			var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
			request.url = urlComponents?.url
			
		case .bodyParams(let params):
			guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
			
			if !(request.allHTTPHeaderFields ?? [:]).keys.contains("Content-Type") {
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			}
			
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .jsonModel(let model):
			guard let data = try? model.toJsonData() else { return }
			
			if !(request.allHTTPHeaderFields ?? [:]).keys.contains("Content-Type") {
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			}
			
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .urlEncodedBody(let params):
			guard let data = mapToArray(dictionary: params).joinedWithAmpersands().data(using: .utf8) else {
				return
			}
			
			if !(request.allHTTPHeaderFields ?? [:]).keys.contains("Content-Type") {
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			}
			
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .urlEncodedModel(let model):
			guard let data = mapToArray(dictionary: model.toDictionary()).joinedWithAmpersands().data(using: .utf8) else {
				return
			}
			
			if !(request.allHTTPHeaderFields ?? [:]).keys.contains("Content-Type") {
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			}
			
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .bodyData(let data):
			if !(request.allHTTPHeaderFields ?? [:]).keys.contains("Content-Type") {
				request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			}
			
			request.httpBody = prepareBodyData(data, boundary: boundary)
			
		case .plain:
			break
		}
	}
	
    private static func mapToArray(dictionary: [String: Any]) -> [String] {
        dictionary.reduce([]) {
            guard let value = valueOrNil($1.value) else { return $0 }
            return $0 + ["\($1.key)=\(value)"]
        }
    }
	
	static func prepareUploadBody(endpointData: EndpointData, boundary: Boundary?) -> Data? {
		switch endpointData {
		case .bodyParams(let params):
			guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else { return nil }
			return prepareBodyData(data, boundary: boundary)
		case .jsonModel(let model):
			guard let data = try? model.toJsonData() else { return nil }
			return prepareBodyData(data, boundary: boundary)
		case .bodyData(let data):
			return prepareBodyData(data, boundary: boundary)
		default:
			return nil
		}
	}
	
	static func prepareBodyData(_ data: Data, boundary: Boundary?) -> Data {
		var finalData = Data()
		if let boundary = boundary {
			finalData = boundary.prepareData(withFileData: data)
		} else {
			finalData = data
		}
		return finalData
	}
}

fileprivate extension Collection where Element == String {
	func joinedWithAmpersands() -> String {
		self.joined(separator: "&")
	}
}
