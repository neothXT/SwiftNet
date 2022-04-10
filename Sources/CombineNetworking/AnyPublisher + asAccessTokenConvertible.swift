//
//  AnyPublisher + asAccessTokenConvertible.swift
//  
//
//  Created by Maciej Burdzicki on 10/04/2022.
//

import Foundation
import Combine

extension AnyPublisher {
	public func asAccessTokenConvertible() throws -> AnyPublisher<AccessTokenConvertible, Error> {
		self.tryMap { output in
			guard let convertedOutput = output as? AccessTokenConvertible else {
				throw CNError.conversionFailed
			}
			
			return convertedOutput
		}
		.eraseToAnyPublisher()
	}
}
