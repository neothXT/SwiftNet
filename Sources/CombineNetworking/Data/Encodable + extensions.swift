//
//  Encodable + toJson.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 23/05/2021.
//

import Foundation

extension Encodable {
	public func toJsonData() throws -> Data {
		try JSONEncoder().encode(self)
	}
	
	public func toDictionary(options: EncodableConversionOptions = .init(rawValue: 0)) -> [String: Any] {
		guard let data = try? toJsonData(), var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
			return [:]
		}
		
		if !options.contains(.keepEmptyCollections) {
			json.filter {
				valueOrNil($0.value) == nil || (collectionCountOrNil($0.value) ?? -1) == 0
			}.forEach {
				json.removeValue(forKey: $0.key)
			}
		}
		
		return json
	}
	
	private func valueOrNil(_ value: Any) -> Any? {
		switch value {
		case Optional<Any>.none:
			return nil
		case Optional<Any>.some(let val):
			return val
		default:
			return value
		}
	}
	
	fileprivate func collectionCountOrNil(_ value: Any) -> Int? {
		if let val = value as? Array<Any> {
			return val.count
		} else if let val = value as? Dictionary<String, Any> {
			return val.count
		} else {
			return nil
		}
	}
}

fileprivate extension Optional where Wrapped: Collection {
	var isNilOrEmpty: Bool {
		self?.isEmpty ?? true
	}
}

public struct EncodableConversionOptions: OptionSet {
	public let rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// Keeps first level empty collections
	public static let keepEmptyCollections = EncodableConversionOptions(rawValue: 1 << 0)
}
