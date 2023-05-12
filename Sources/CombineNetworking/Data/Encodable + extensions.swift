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
			json = (removeEmptyCollections(from: json) as? [String: Any]) ?? [:]
		}
		
		return json
	}
	
	private func removeEmptyCollections(from input: Any) -> Any {
		if var array = input as? [Any?] {
			array.enumerated().forEach { index, value in
				guard let value else {
					array.remove(at: index)
					return
				}
				guard let count = collectionCountOrNil(value) else {
					if valueOrNil(value) == nil {
						array.remove(at: index)
					}
					return
				}
				if count == 0 {
					array.remove(at: index)
				} else {
					array[index] = removeEmptyCollections(from: value)
				}
			}
			return array
		} else if var dict = input as? [String: Any?] {
			dict.forEach { key, value in
				guard let value else {
					dict.removeValue(forKey: key)
					return
				}
				guard let count = collectionCountOrNil(value) else {
					if valueOrNil(value) == nil {
						dict.removeValue(forKey: key)
					}
					return
				}
				if count == 0 {
					dict.removeValue(forKey: key)
				} else {
					dict[key] = removeEmptyCollections(from: value)
				}
			}
			return dict
		}
		return input
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
	
	/// Keeps empty collections in final output
	public static let keepEmptyCollections = EncodableConversionOptions(rawValue: 1 << 0)
}
