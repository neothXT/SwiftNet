//
//  AccessTokenStrategy.swift
//  
//
//  Created by Maciej Burdzicki on 11/03/2022.
//

import Foundation

public enum AccessTokenStrategy {
	case global, `default`, custom(String)
	
	var storingLabel: String? {
		switch self {
		case .global:
			return "CombineNetworking"
		case .custom(let label):
			return label
		default:
			return nil
		}
	}
}

extension AccessTokenStrategy: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.global, .global), (.default, .default):
			return true
			
		case (.custom(let lCustom), .custom(let rCustom)):
			return lCustom == rCustom
			
		default:
			return false
		}
	}
}
