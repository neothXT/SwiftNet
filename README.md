![alt [version]](https://img.shields.io/github/v/release/neothXT/CombineNetworking) ![alt cocoapods available](https://img.shields.io/badge/CocoaPods-1.11.0-blue) ![alt spm available](https://img.shields.io/badge/SPM-available-green) ![alt carthage unavailable](https://img.shields.io/badge/Carthage-unavailable-red)

# CombineNetworking
Meet CombineNetworking. Super lightweight and crazy easy to use framework to help you create and handle your network requests in a convenient way.
Besides basic network requests, CombineNetworking allows you to easily send your requests securely with a simple SSL and Certificate pinning mechanisms. But that's not all. With CombineNetworking you can also effortlessly handle authorization tokens with built-in automatic authorization mechanism.

## Installation (using CocoaPods)

`pod 'CombineNetworking'`

##### Note that in order to use CombineNetworking, your iOS Deployment Target has to be 13.0 or newer. If you code for macOS, your Deployment Target has to be 10.15 or newer.

### CombineNetworking 2.0.0 won't be available on CocoaPods unless SwiftSyntax package (which is required to enable Swift Macros) becomes available on CocoaPods.

#### CombineNetworking is also available via SPM (Swift Package Manager)

## Key functionalities
- Sending requests easily using `Endpoint` models
- SSL and Certificate pinning with just 2 lines of code
- WebSocket connection support with `CNWebSocket`
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
CNConfig.pinningModes = [.ssl, .certificate]
```

Please remember that SSL/Certificate pinning requires certificate file to be attached in your project. Certificates and SSL keys are autmatically loaded by CombineNetworking.

### Automatic authorization mechanism

Handling authorization callbacks with CombineNetworking is ridiculously easy. To use it with your `Endpoint` all you have to do is to add `requiresAccessToken` and `callbackPublisher` fields as presented below:

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
        try? CNProvider<TodosEndpoint>().publisher(for: .token, responseType: CNAccessToken?.self).asAccessTokenConvertible()
    }
}
```

See? Easy peasy! Keep in mind that your token model has to conform to `AccessTokenConvertible`.

### CNConfig properties and methods

- `pinningModes` - turns on/off SSL and Certificate pinning. Available options are `.ssl`, `.certificate` or both.
- `sitesExcludedFromPinning` - list of website addresses excluded from SSL/Certificate pinning check 
- `defaultJSONDecoder` - use this property to set globally your custom JSONDecoder
- `defaultAccessTokenStrategy` - global strategy for storing access tokens. Available options are `.global` and `.custom(String)`.
- `keychainInstance` - keychain instance used by CombineNetworking to store/fetch access tokens from Apple's Keychain. If not provided, safe storage will be turned off (more info below)
- `accessTokenStorage` - an instance of an object implementing AccessTokenStorage protocol. It's used to manipulate access token. By default it uses built-in `CNStorage`. To use different storage, provide your own instance.

### Access Token Strategies

CombineNetworking allows you to specify access token strategies globally as well as individually for each endpoint. You can specify your strategy by setting it for `CNConfig.defaultAccessTokenStrategy` or inside your `Endpoint` by setting value for field `accessTokenStrategy`.
Available options are:
- `.global` - uses global label to store access token
- `.custom(String)` - with this option you can specify your own label to store access token and use it among as many endpoints as you wish

Thanks to access token strategy being set both globally (via `CNConfig`) and individually (inside `Endpoint`), you can mix different strategies in your app!

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

CombineNetworking's CNProvider uses iOS built-in Logger (if running on iOS 14 or newer) and custom debug-mode-only logger by default for each and every request.

### Network connection monitor

CombineNetowrking allows you continuously monitor network connection status. 
If you want to subscribe to a network connection monitor's publisher, you can do it like this:

```Swift
private var subscriptions: Set<AnyCancellable> = []

func subscribeForNetworkChanges() {
    CNNetworkMonitor.publisher()
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

CombineNetworking allows you to store your access tokens in keychain. Using keychain to store your access tokens requires you to provide keychain instance by setting value of `CNConfig.keychainInstance`.

Please remember Apple's Keychain doesn't automatically remove entries created by an app upon its deletion. Do not worry, however. Only your app can access those entries, nevertheless, it's up to you to make sure those are removed from keychain if not needed anymore. CombineNetworking provides method `CNConfig.removeAccessToken(...)` to help you do it.
### Subscribe to a publisher

```Swift
private var subscriptions: Set<AnyCancellable> = []
var todo: Todo?

func subscribeForTodos() {
    CNProvider<TodosEndpoint>().publisher(for: .todos(1), responseType: Todo?.self)
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

In case of request failure, CombineNetworking returns stuct of type `CNError` reflected as `Error`.

```Swift
public struct CNError: Error {
    let type: ErrorType
    let details: CNErrorDetails?
    let data: Data?
}
```

Available error types are: `failedToBuildRequest`, `failedToMapResponse`, `unexpectedResponse`, `authenticationFailed`, `notConnected`, `emptyResponse`, `noInternetConnection` and `conversionFailed`.

`CNErrorDetails` looks like following:

```Swift
public struct CNErrorDetails {
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
final class CombineNetworkingTests: XCTestCase {
    private let provider = CNProvider<RemoteEndpoint>()
	
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
final class CombineNetworkingTests: XCTestCase {
    private let provider = CNProvider<RemoteEndpoint>()
	
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

CombineNetworking also allows you to connect with WebSockets effortlessly. Simply use `CNWebSocket` like this:

```Swift
let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
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

From release 2.0.0 CombineNetworking introduces new way of building and executing network requests.

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
- Determine method and path of your endpoint requests with `@GET(url:)`, `@POST(url:)`, `@PUT(url:)`, `@DELETE(url:)`, `@PATCH(url:)`, `@CONNECT(url:)`, `@HEAD(url:)`, `@OPTIONS(url:)`, `@QUERY(url:)` or `@TRACE(url:)`

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

And that's it. Enjoy :)
