// The Swift Programming Language
// https://docs.swift.org/swift-book

import SNUtilities

@attached(member, names: named(url), named(identifier), named(staticIdentifier))
public macro Endpoint(url: String) = #externalMacro(module: "SNMacros", type: "EndpointMacro")

// MARK: - RequestMethod macros
@attached(accessor)
public macro NetworkRequest(url: String, method: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "NetworkRequestMacro")

@attached(accessor)
public macro GET(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "GetMacro")

@attached(accessor)
public macro POST(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "PostMacro")

@attached(accessor)
public macro PUT(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "PutMacro")

@attached(accessor)
public macro DELETE(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "DeleteMacro")

@attached(accessor)
public macro PATCH(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "PatchMacro")

@attached(accessor)
public macro CONNECT(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "ConnectMacro")

@attached(accessor)
public macro HEAD(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "HeadMacro")

@attached(accessor)
public macro OPTIONS(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "OptionsMacro")

@attached(accessor)
public macro QUERY(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "QueryMacro")

@attached(accessor)
public macro TRACE(url: String, descriptor: EndpointDescriptor = .init()) = #externalMacro(module: "SNMacros", type: "TraceMacro")
