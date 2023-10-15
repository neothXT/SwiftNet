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
	private static var postItems: [Post] = [
		Post(userId: 1, id: 1, title: "Title1", body: "Body1"),
		Post(userId: 2, id: 2, title: "Title2", body: "Body2"),
		Post(userId: 3, id: 3, title: "Title3", body: "Body3"),
		Post(userId: 4, id: 4, title: "Title4", body: "Body4"),
		Post(userId: 5, id: 5, title: "Title5", body: "Body5")
	]
	
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
	
	var mockedData: Codable? {
		switch self {
		case .posts:
			return RemoteEndpoint.postItems
		case .post(let post):
			RemoteEndpoint.postItems.append(post)
			return RemoteEndpoint.postItems
		default:
			return nil
		}
	}
	
	var accessTokenStrategy: AccessTokenStrategy {
		switch self {
		case .posts:
			return .custom("someLabel")
		default:
			return .global
		}
	}
    
    var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? {
        CurrentValueSubject<AccessTokenConvertible, Error>(CNAccessToken(access_token: "testAsyncTask"))
            .eraseToAnyPublisher()
    }
}
