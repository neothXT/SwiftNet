//
//  CNProvider+defaultURLMapper.swift
//  
//
//  Created by Maciej Burdzicki on 29/07/2022.
//

import Foundation

public extension CNProvider {
	final class func defaultURLMapper(for endpoint: Endpoint) -> URL? {
		endpoint.baseURL?.appendingPathComponent(endpoint.path)
	}
}
