//
//  EndpointData.swift
//  SwiftNet
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

public enum EndpointData {
	case plain
	case queryString(String)
	case queryParams([String: Any])
	case bodyParams([String: Any])
	case urlEncodedBody([String: Any])
	case urlEncodedModel(Encodable)
	case jsonModel(Encodable)
	case bodyData(Data)
}
