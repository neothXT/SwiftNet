//
//  TestEndpoint.swift
//
//
//  Created by Maciej Burdzicki on 21/06/2023.
//

import Foundation
import CombineNetworking
import CombineNetworkingMacros

final class EndpointDescriptorFactory {
    private init() {}
    
    static func todosDescriptor() -> EndpointDescriptor {
        .init(urlValues: [.init(key: "id", value: "1")])
    }
}

@Endpoint(url: "https://jsonplaceholder.typicode.com/")
struct TestEndpoint: EndpointModel {
    private let id = 1 // used by todosV2
    @GET(url: "todos/#{id}#") var todos: EndpointBuilder<Todo>
    @GET(url: "todos/${id}$") var todosV2: EndpointBuilder<Todo>
    @GET(url: "todos/#{id}#", descriptor: EndpointDescriptorFactory.todosDescriptor()) var todosV3: EndpointBuilder<Todo>
    @GET(url: "comments") var comments: EndpointBuilder<Data>
    @POST(url: "posts") var post: EndpointBuilder<Data>
}
