//
//  EndpointData.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

public enum EndpointData {
	case plain
	case queryString(String)
	case queryParams([String: Any])
	case bodyParams([String: Any])
	case urlEncoded([String: Any])
	case jsonModel(Encodable)
	case bodyData(Data)
}
