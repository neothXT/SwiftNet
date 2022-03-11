//
//  TodosEndpoint.swift
//  CombineNetworkingTests
//
//  Created by Maciej Burdzicki on 20/05/2021.
//

import Foundation
import CombineNetworking

enum RemoteEndpoint {
	case todos
	case posts
	case post(Post)
	case dictPost([String: Any])
	case dictGet([String: Any])
}

extension RemoteEndpoint: Endpoint {
	var baseURL: URL? {
		switch self {
		case .posts:
			return URL(string: "https://jsonplaceholder7.typicode.com/")
		default:
			return URL(string: "https://jsonplaceholder.typicode.com/")
		}
	}
	
	var path: String {
		switch self {
		case .dictGet:
			return "comments"
		case .todos:
			return "todos/1"
		case .posts:
			return "CNErrorExample"
			
		case .post, .dictPost:
			return "posts"
		}
	}
	
	var method: RequestMethod {
		switch self {
		case .post, .dictPost:
			return .post
		default:
			return .get
		}
	}
	
	var headers: [String : Any]? {
		nil
	}
	
	var data: EndpointData {
		switch self {
		case .post(let post):
			return .jsonModel(post)
		case .dictPost(let dict):
			return .bodyParams(dict)
		case .dictGet(let dict):
			return .queryParams(dict)
		default:
			return .plain
		}
	}
	
}
