//
//  AnyPublisher + asAccessTokenConvertible.swift
//  
//
//  Created by Maciej Burdzicki on 10/04/2022.
//

import Foundation
import Combine


extension AnyPublisher {
	/// Converts publisher to return object responding to AccessTokenConvertible in case of success
	public func asAccessTokenConvertible() throws -> AnyPublisher<AccessTokenConvertible, Error> {
		self.tryMap { output in
			guard let convertedOutput = output as? AccessTokenConvertible else {
				throw SNError(type: .conversionFailed)
			}
			
			return convertedOutput
		}
		.eraseToAnyPublisher()
	}
}
