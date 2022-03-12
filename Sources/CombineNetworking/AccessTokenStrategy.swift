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
			return "com.neothxt.combinenetworking"
		case .custom(let label):
			return label
		default:
			return nil
		}
	}
}
