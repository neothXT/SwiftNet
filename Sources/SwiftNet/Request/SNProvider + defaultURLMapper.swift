//
//  SNProvider + defaultURLMapper.swift
//  
//
//  Created by Maciej Burdzicki on 29/07/2022.
//

import Foundation

public extension SNProvider {
	final class func defaultURLMapper(for endpoint: Endpoint) -> URL? {
        guard endpoint.path != "" else { return endpoint.baseURL }
		return endpoint.baseURL?.appendingPathComponent(endpoint.path)
	}
}
