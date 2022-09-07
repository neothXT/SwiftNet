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
			if let value = valueOrNil(child.value) {
				output[child.label!] = value
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
}

fileprivate extension Optional where Wrapped: Collection {
	var isNilOrEmpty: Bool {
		self?.isEmpty ?? true
	}
}
