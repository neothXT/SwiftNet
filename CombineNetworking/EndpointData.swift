//
//  EndpointData.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

public enum EndpointData {
	case plain
	case queryParams([String: Any])
	case bodyParams([String: Any])
	case urlEncoded([String: Any])
	case jsonModel(Encodable)
}
