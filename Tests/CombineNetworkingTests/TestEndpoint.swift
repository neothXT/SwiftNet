//
//  TestEndpoint.swift
//
//
//  Created by Maciej Burdzicki on 21/06/2023.
//

import Foundation
import CombineNetworking
import CombineNetworkingMacros

@Endpoint(url: "https://jsonplaceholder.typicode.com/")
struct TestEndpoint: EndpointModel {
    @GET(url: "todos/#{id}#")var todos: EndpointBuilder<Todo>
    @GET(url: "comments") var comments: EndpointBuilder<Data>
    @POST(url: "posts") var post: EndpointBuilder<Data>
}
