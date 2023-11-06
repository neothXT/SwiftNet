![alt [version]](https://img.shields.io/github/v/release/neothXT/SwiftNet) ![alt cocoapods available](https://img.shields.io/badge/CocoaPods-v1.11.0-blue) ![alt spm available](https://img.shields.io/badge/SPM-available-green) ![alt carthage unavailable](https://img.shields.io/badge/Carthage-unavailable-red)

# SwiftNet
After adding support for Swift Concurrency, CombineNetworking becomes SwiftNet! A super lightweight and crazy easy to use framework to help you create and handle your network requests in a convenient way.
Besides basic network requests, SwiftNet allows you to easily send your requests securely with a simple SSL and Certificate pinning mechanisms. But that's not all. With SwiftNet you can also effortlessly handle authorization tokens with built-in automatic authorization mechanism.

## Installation (using CocoaPods)

`pod 'CombineNetworking'`

##### Note that in order to use SwiftNet, your iOS Deployment Target has to be 13.0 or newer. If you code for macOS, your Deployment Target has to be 10.15 or newer.

#### SwiftNet 2.0.0 and above won't be available on CocoaPods unless SwiftSyntax package (which is required to enable Swift Macros) becomes available on CocoaPods. To fetch the latest versions, please use SPM (Swift Package Manager).

## Key functionalities
- Sending requests easily using `Endpoint` models
- SSL and Certificate pinning with just 2 lines of code
- WebSocket connection support with `SNWebSocket`
- Secure access token storage with Keychain
- Access token storing strategy - configure `global`, `endpoint specific` (`default`) or `custom` strategy for all or just some endpoints
- Automated refresh token/callback requests

## Basic Usage

1. [Enum-powered networking](#create-an-endpoint-to-work-with)
2. [Macro-powered networking](#macro-powered-networking)

### Create an Endpoint to work with
```Swift
enum TodosEndpoint {
    case todos(Int)
}

extension TodosEndpoint: Endpoint {
    var baseURL: URL? {
        URL(string: "https://jsonplaceholder.typicode.com/")
    }
	
    var path: String {
        switch self {
        case .todos:
            return "todos"
        }
    }
	
    var method: RequestMethod {
        .get
    }
	
    var headers: [String : Any]? {
        nil
    }
	
    var data: EndpointData {
        switch self {
        case .todos(let id):
            return .queryParams(["id": id])
        }
    }
}
```

`RequestMethod` is an enum with following options: `.get`, `.post`, `.put`, `.delete`, `patch`.
`EndpointData` is also an enum with following options: 
- `.plain`
- `.queryParams([String: Any])`
- `.queryString(String)`
- `.bodyData(Data)`
- `.bodyParams([String: Any])` - takes `Dictionary` and parses it into `Data` to send in request's body
- `.urlEncodedBody([String: Any])` - takes `Dictionary` and parses it into url encoded `Data` to send in request's body
- `.urlEncodedModel(Encodable)` - takes `Encodable` model and parses it into url encoded `Data` to send in request's body
- `.jsonModel(Encodable)` - similar to `.dataParams` except this one takes `Encodable` and parses it into `Data` to send in request's body

### Enable SSL and/or Certificate pinning (optional)

To turn SSL and/or Certificate pinning in your app just add:

```Swift
SNConfig.pinningModes = [.ssl, .certificate]
```

Please remember that SSL/Certificate pinning requires certificate file to be attached in your project. Certificates and SSL keys are autmatically loaded by SwiftNet.

### Automatic authorization mechanism

Handling authorization callbacks with SwiftNet is ridiculously easy. To use it with your `Endpoint` all you have to do is to add `requiresAccessToken` and `callbackPublisher` fields as presented below:

```Swift

enum TodosEndpoint {
    case token
    case todos(Int)
}

extension TodosEndpoint: Endpoint {
    //Setup all the required properties like baseURL, path, etc...
		
    //... then determine which of your endpoints require authorization...
    var requiresAccessToken: Bool {
        switch self {
        case .token:
            return false
     
        default:
            return true
        }
    }
	
    //... and prepare callbackPublisher to handle authorization callbacks
    var callbackPublisher: AnyPublisher<AccessTokenConvertible?, Error>? {
        try? SNProvider<TodosEndpoint>().publisher(for: .token, responseType: SNAccessToken?.self).asAccessTokenConvertible()
    }
}
```

See? Easy peasy! Keep in mind that your token model has to conform to `AccessTokenConvertible`.

### SNConfig properties and methods

- `pinningModes` - turns on/off SSL and Certificate pinning. Available options are `.ssl`, `.certificate` or both.
- `sitesExcludedFromPinning` - list of website addresses excluded from SSL/Certificate pinning check 
- `defaultJSONDecoder` - use this property to set globally your custom JSONDecoder
- `defaultAccessTokenStrategy` - global strategy for storing access tokens. Available options are `.global` and `.custom(String)`.
- `keychainInstance` - keychain instance used by SwiftNet to store/fetch access tokens from Apple's Keychain. If not provided, safe storage will be turned off (more info below)
- `accessTokenStorage` - an instance of an object implementing AccessTokenStorage protocol. It's used to manipulate access token. By default it uses built-in `SNStorage`. To use different storage, provide your own instance.
- `accessTokenErrorCodes` - array containing error codes that should trigger access token refresh action. Default: [401].

### Access Token Strategies

    SwiftNet allows you to specify access token strategies globally as well as individually for each endpoint. You can specify your strategy by setting it for `SNConfig.defaultAccessTokenStrategy` or inside your `Endpoint` by setting value for field `accessTokenStrategy`.
Available options are:
- `.global` - uses global label to store access token
- `.custom(String)` - with this option you can specify your own label to store access token and use it among as many endpoints as you wish

Thanks to access token strategy being set both globally (via `SNConfig`) and individually (inside `Endpoint`), you can mix different strategies in your app!

### Access Token manipulations

If you want, you can manipulate access tokens yourself.

Available methods are:

- `setAccessToken(_ token:, for:)`
- `accessToken(for:)`
- `removeAccessToken(for:)`

- `setGlobalAccessToken(_ token:)`
- `globalAccessToken()`
- `removeGlobalAccessToken()`

### Event logging

SwiftNet's SNProvider uses iOS built-in Logger (if running on iOS 14 or newer) and custom debug-mode-only logger by default for each and every request.

### Network connection monitor

CombineNetowrking allows you continuously monitor network connection status. 
If you want to subscribe to a network connection monitor's publisher, you can do it like this:

```Swift
private var subscriptions: Set<AnyCancellable> = []

func subscribeForNetworkChanges() {
    SNNetworkMonitor.publisher()
        .sink { status in
            switch status {
            case .wifi:
                // Do something
            case .cellular:
                // Do something else
            case .unavailable:
                // Show connection error
            }
        }
        .store(in: &subscriptions)
}
```

### Safe storage using Keychain

SwiftNet allows you to store your access tokens in keychain. Using keychain to store your access tokens requires you to provide keychain instance by setting value of `SNConfig.keychainInstance`.

Please remember Apple's Keychain doesn't automatically remove entries created by an app upon its deletion. Do not worry, however. Only your app can access those entries, nevertheless, it's up to you to make sure those are removed from keychain if not needed anymore. SwiftNet provides method `SNConfig.removeAccessToken(...)` to help you do it.
### Subscribe to a publisher

```Swift
private var subscriptions: Set<AnyCancellable> = []
var todo: Todo?

func subscribeForTodos() {
    SNProvider<TodosEndpoint>().publisher(for: .todos(1), responseType: Todo?.self)
        .catch { (error) -> Just<Todo?> in
            print(error)
            return Just(nil)
        }
        .assign(to: \.todo, on: self)
        .store(in: &subscriptions)
}
```

If you want to subscribe to a publisher but doesn't want to immediately decode the body but rather want to get raw Data object, use `rawPublisher` instead.

### Error handling

In case of request failure, SwiftNet returns stuct of type `SNError` reflected as `Error`.

```Swift
public struct SNError: Error {
    let type: ErrorType
    let details: SNErrorDetails?
    let data: Data?
}
```

Available error types are: `failedToBuildRequest`, `failedToMapResponse`, `unexpectedResponse`, `authenticationFailed`, `notConnected`, `emptyResponse`, `noInternetConnection` and `conversionFailed`.

`SNErrorDetails` looks like following:

```Swift
public struct SNErrorDetails {
    public let statusCode: Int
    public let localizedString: String
    public let url: URL?
    public let mimeType: String?
    public let headers: [AnyHashable: Any]?
    public let data: Data?
}
```

### Simplified testing

If you want to run simple tests on your request, just to confirm the status code of the response met the expectations set for a given endpoint you can just run `testRaw()` method like this:

```Swift
final class SwiftNetTests: XCTestCase {
    private let provider = SNProvider<RemoteEndpoint>()
	
    func testTodoFetch() throws {
        let expectation = expectation(description: "Test todo fetching request")
	var subscriptions: Set<AnyCancellable> = []
		
	provider.testRaw(.todos, usingMocks: false, storeIn: &subscriptions) {
	    expectation.fulfill()
	}
		
        wait(for: [expectation], timeout: 10)
    } 
}
```

... and if you want to test your request by confirming both the status code and the response model, use `test()` method like this:

```Swift
final class SwiftNetTests: XCTestCase {
    private let provider = SNProvider<RemoteEndpoint>()
	
    func testTodoFetchWithModel() throws {
        let expectation = expectation(description: "Test todo fetching request together with its response model")
	var subscriptions: Set<AnyCancellable> = []
		
	provider.test(.todos, responseType: Todo.self, usingMocks: false, storeIn: &subscriptions) {
	    expectation.fulfill()
	}
		
        wait(for: [expectation], timeout: 10)
    } 
}
```

You can also use mocked data in your tests. To do so, just add `mockedData` to your `Endpoint` and when calling `provider.test()` or `provider.testRaw()` set `usingMocks` to `true`.

### WebSockets

SwiftNet also allows you to connect with WebSockets effortlessly. Simply use `SNWebSocket` like this:

```Swift
let webSocket = SNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
webSocket.connect()
webSocket.listen { result in
    switch result {
    case .success(let message):
        switch message {
	case .data(let data):
	    print("Received binary: \(data)")
	case .string(let string):
	    print("Received string: \(string)")
	}
    default:
	return
    }
}

webSocket.send(.string("Test message")) {
    if let error = $0 {
        log(error.localizedDescription)
    }
}
```

If you want to close connection, just call `webSocket.disconnect()`.

## Macro-powered networking

From release 2.0.0 SwiftNet introduces new way of building and executing network requests.
To enable SwiftNet's macros, add to your file:

```Swift
import SwiftNetMacros
```

### Endpoint creation

Start by creating struct or class implementing `EndpointModel` protocol.

```Swift
public protocol EndpointModel {
    var defaultAccessTokenStrategy: AccessTokenStrategy { get }
    var defaultHeaders: [String: Any] { get }
    var callbackPublisher: AnyPublisher<AccessTokenConvertible, Error>? { get }
}
```

Once done, you're ready to create your endpoint. Each endpoint request should be of type `EndpointBuilder<T: Codable & Equatable>`.

- Use `@Endpoint(url:)` macro to setup baseURL of your endpoint
- Determine method and path of your endpoint requests with `@GET(url:descriptor:)`, `@POST(url:descriptor:)`, `@PUT(url:descriptor:)`, `@DELETE(url:descriptor:)`, `@PATCH(url:descriptor:)`, `@CONNECT(url:descriptor:)`, `@HEAD(url:descriptor:)`, `@OPTIONS(url:descriptor:)`, `@QUERY(url:descriptor:)` or `@TRACE(url:descriptor:)`
- `descriptor` param is optional

```Swift
@Endpoint(url: "https://jsonplaceholder.typicode.com/")
struct TestEndpoint: EndpointModel {
    @GET(url: "todos/1") var todos: EndpointBuilder<Todo>
    @GET(url: "comments") var comments: EndpointBuilder<Data>
    @POST(url: "posts") var post: EndpointBuilder<Data>
}
```

### Build a request

Now that your endpoint is ready, time to build a request. 

```Swift
class NetworkManager {
    private var subscriptions: Set<AnyCancellable> = []
    private let endpoint = TestEndpoint()
    
    var todo: Todo?

    func callRequest() {
        endpoint
            .comments
            .setRequestParams(.queryParams(["postId": 1]))
            .buildPublisher()
            .catch { (error) -> Just<Todo?> in
                print(error)
                return Just(nil)
            }
            .assign(to: \.todo, on: self)
            .store(in: &subscriptions)
    }
}
```

### Requests with dynamic values in URL

Sometimes we need to inject some variable into the URL of our request. To do so, you can use two patterns: `${variable}$` or `#{variable}#`.

#### `${variable}$` should be used for variables that already exist in your code

```Swift
@Endpoint(url: "${myUrl}$")
struct MyStruct: EndpointModel {
}
```

After macro expansion will look like

```Swift
struct MyStruct: EndpointModel {
    let url = "\(myUrl)"
} 
```

#### `#{variable}#` should be used for variables you want to provide yourself when building your request

```Swift
@Endpoint(url: "www.someurl.com/comments/#{id}#")
struct MyStruct: EndpointModel {
}
```

After macro expansion will look like

```Swift
struct MyStruct: EndpointModel {
    let url = "www.someurl.com/comments/#{id}#"
} 
```

To then swap it for an actual value, use `.setUrlValue(_ value: String, forKey key: String)` when building your request like

```Swift
func buildRequest() async throws -> [Comment] {
    endpoint
        .comments
        .setUrlValue("1", forKey: "id")
        .buildAsyncTask()
}
```

### Alternative "build a request" flow

From version 2.0.1 SwiftNet allows you to speed things up even more by generating EndpointBuilders with descriptors. Thanks to descriptors, you can extract endpoint setup to reduce number of lines required to build working endpoint.

```Swift

final class EndpointDescriptorFactory {
    private init() {}
    
    static func singleTodoDescriptor() -> EndpointDescriptor {
        .init(urlValues: [.init(key: "id", value: "1")])
    }
} 

@Endpoint(url: "https://jsonplaceholder.typicode.com/")
struct TestEndpoint: EndpointModel {
    @GET(url: "todos/#{id}#", descriptor: EndpointDescriptorFactory.singleTodoDescriptor()) var singleTodo: EndpointBuilder<Todo>
}
```

Now you can just build your request and it'll already know how to translate `#{id}#`.

```Swift
func buildRequest() async throws -> Todo {
    endpoint
        .singleTodo
        .buildAsyncTask()
}
```

And that's it. Enjoy :)
