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
	
	public func toDictionary() -> [String: Any] {
		var output: [String: Any] = [:]
		let mirror = Mirror(reflecting: self)
		
		mirror.children.filter { !$0.label.isNilOrEmpty }.forEach { child in
			guard let value = valueOrNil(child.value) else { return }
			
			if let array = value as? Array<Any> {
				guard array.count > 0 else { return }
				output[child.label!] = array.compactMap { arrayValue -> Any? in
					guard let value = valueOrNil(arrayValue) else { return nil }
					return rawValueIfNeeded(value)
				}
			} else if let dict = value as? Dictionary<String, Any> {
				guard Array(dict.keys).count > 0 else { return }
				output[child.label!] = dict.filter { _, value in
					valueOrNil(value) != nil
				}
			} else {
				output[child.label!] = rawValueIfNeeded(value)
			}
		}
		
		return output
	}
	
	fileprivate func valueOrNil(_ value: Any) -> Any? {
		switch value {
		case Optional<Any>.none:
			return nil
		case Optional<Any>.some(let val):
			return val
		default:
			return value
		}
	}
	
	private func rawValueIfNeeded(_ value: Any) -> Any {
		let mirror = Mirror(reflecting: value)
		guard mirror.displayStyle == .enum, let value = value as? any RawRepresentable else { return value }
		return value.rawValue
	}
}

fileprivate extension Optional where Wrapped: Collection {
	var isNilOrEmpty: Bool {
		self?.isEmpty ?? true
	}
}
