// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "CNMacros", type: "StringifyMacro")

@attached(member, names: named(url))
public macro Endpoint(url: String) = #externalMacro(module: "CNMacros", type: "EndpointMacro")

// MARK: - RequestMethod macros
@attached(accessor)
public macro NetworkRequest(url: String, method: String) = #externalMacro(module: "CNMacros", type: "NetworkRequestMacro")

@attached(accessor)
public macro GET(url: String) = #externalMacro(module: "CNMacros", type: "GetMacro")

@attached(accessor)
public macro POST(url: String) = #externalMacro(module: "CNMacros", type: "PostMacro")

@attached(accessor)
public macro PUT(url: String) = #externalMacro(module: "CNMacros", type: "PutMacro")

@attached(accessor)
public macro DELETE(url: String) = #externalMacro(module: "CNMacros", type: "DeleteMacro")

@attached(accessor)
public macro PATCH(url: String) = #externalMacro(module: "CNMacros", type: "PatchMacro")

@attached(accessor)
public macro CONNECT(url: String) = #externalMacro(module: "CNMacros", type: "ConnectMacro")

@attached(accessor)
public macro HEAD(url: String) = #externalMacro(module: "CNMacros", type: "HeadMacro")

@attached(accessor)
public macro OPTIONS(url: String) = #externalMacro(module: "CNMacros", type: "OptionsMacro")

@attached(accessor)
public macro QUERY(url: String) = #externalMacro(module: "CNMacros", type: "QueryMacro")

@attached(accessor)
public macro TRACE(url: String) = #externalMacro(module: "CNMacros", type: "TraceMacro")
