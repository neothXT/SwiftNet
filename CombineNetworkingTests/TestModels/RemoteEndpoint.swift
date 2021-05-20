//
//  TodosEndpoint.swift
//  SwiftUITraining
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation

enum RemoteEndpoint {
	case todos
}

extension RemoteEndpoint: Endpoint {
	var baseURL: URL {
		URL(string: "https://jsonplaceholder.typicode.com/")!
	}
	
	var path: String {
		switch self {
		case .todos:
			return "todos/1"
		}
	}
	
	var method: RequestMethod {
		.get
	}
	
	var headers: [String : Any]? {
		nil
	}
	
	var data: EndpointData {
		.plain
	}
	
}
