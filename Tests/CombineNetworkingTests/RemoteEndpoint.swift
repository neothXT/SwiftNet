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
	case stringGet(String)
	case dictPost([String: Any])
	case dictGet([String: Any])
	case urlEncodedBody([String: Any])
	case urlEncoded(Encodable)
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
		case .dictGet, .stringGet:
			return "comments"
		case .todos:
			return "todos/1"
		case .posts:
			return "CNErrorExample"
			
		case .post, .dictPost:
			return "posts"
			
		default:
			return ""
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
		case .stringGet(let string):
			return .queryString(string)
		case .urlEncodedBody(let dict):
			return .urlEncodedBody(dict)
		case .urlEncoded(let model):
			return .urlEncodedModel(model)
		default:
			return .plain
		}
	}
	
}
