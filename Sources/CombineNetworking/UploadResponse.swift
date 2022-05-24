//
//  UploadResponse.swift
//  
//
//  Created by Maciej Burdzicki on 23/05/2022.
//

import Foundation

public enum UploadResponse<T: Codable & Equatable>: Equatable {
	case progress(percentage: Double)
	case response(data: T?)
	case authError
	case error(Int, Data?)
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.progress(let left), .progress(let right)):
			return left == right
		case (.response(let left), .response(let right)):
			return left == right
		case (.authError, .authError):
			return true
		case (.error(let left, let lData), .error(let right, let rData)):
			return left == right && lData == rData
		default:
			return false
		}
	}
}
