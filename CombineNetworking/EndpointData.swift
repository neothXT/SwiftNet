//
//  EndpointData.swift
//  CombineNetworking
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

public enum EndpointData {
	case plain, queryParams([String: Any]), dataParams([String: Any]), jsonModel(Encodable)
}
