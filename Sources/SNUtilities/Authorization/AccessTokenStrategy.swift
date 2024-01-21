//
//  AccessTokenStrategy.swift
//  
//
//  Created by Maciej Burdzicki on 11/03/2022.
//

public enum AccessTokenStrategy {
	case global, custom(String)
	
	public var storingLabel: String {
		switch self {
		case .global:
			return "accessToken_SwiftNet"
		case .custom(let label):
			return "accessToken_\(label)"
		}
	}
}

extension AccessTokenStrategy: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.global, .global):
			return true
			
		case (.custom(let lCustom), .custom(let rCustom)):
			return lCustom == rCustom
			
		default:
			return false
		}
	}
}
