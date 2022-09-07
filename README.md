![alt [version]](https://img.shields.io/github/v/release/neothXT/CombineNetworking) ![alt cocoapods available](https://img.shields.io/badge/Cocoapods-available-green) ![alt spm available](https://img.shields.io/badge/SPM-available-green) ![alt carthage unavailable](https://img.shields.io/badge/Carthage-unavailable-red)

# CombineNetworking
Meet CombineNetworking. Super lightweight and crazy easy to use framework to help you create and handle your network requests in a convenient way.
Besides basic network requests, CombineNetworking allows you to easily send your requests securely with a simple SSL and Certificate pinning mechanisms. But that's not all. With CombineNetworking you can also effortlessly handle authorization tokens with built-in automatic authorization mechanism.

## Installation (using CocoaPods)

`pod 'CombineNetworking'`

##### Note that in order to use CombineNetworking, your iOS Deployment Target has to be 13.0 or newer. If you code for macOS, your Deployment Target has to be 10.15 or newer.

#### CombineNetworking is also available via SPM (Swift Package Manager)

## Key functionalities
- Sending requests easily using `Endpoint` models
- SSL and Certificate pinning with just 2 lines of code
- WebSocket connection support with `CNWebSocket`
- Secure access token storage with KeyChain (thanks to KeychainAccess framework)
- Access token storing strategy - configure `global`, `endpoint specific` (`default`) or `custom` strategy for all or just some endpoints
- Automated refresh token/callback requests

## Basic Usage

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
- `.bodyData([String: Any])`
- `.bodyParams([String: Any])` - takes `Dictionary` and parses it into `Data` to send in request's body
- `.urlEncodedBody([String: Any])` - takes `Dictionary` and parses it into `Data` to send in request's body
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
- `defaultAccessTokenStrategy` - global strategy for storing access tokens. Available options are `.global`, `.default` and `.custom(String)`.
- `storeTokensInKeychain` - turns on/off safe storage (more info below)
- `keychainInstance` - keychain instance used by CombineNetworking to store/fetch access tokens from Apple's Keychain  (more info below)
- `setAccessToken(_ token: CNAccessToken?, for endpoint: Endpoint)` - saves new access token
- `accessToken(for endpoint: Endpoint)` - fetches access token for a given endpoint (if exists)
- `removeAccessToken(for endpoint: Endpoint? = nil)` - removes access token for a given endpoint or the global one (if exists)

### Access Token Strategies

CombineNetworking allows you to specify access token strategies globally as well as individually for each endpoint. You can specify your strategy by setting it for `CNConfig.defaultAccessTokenStrategy` or inside your `Endpoint` by setting value for field `accessTokenStrategy`.
Available options are:
- `.global` - uses global label to store access token
- `.default` - uses endpoint identifiers as labels to store access tokens
- `.custom(String)` - with this option you can specify your own label to store access token and use it among as many endpoints as you wish

Thanks to access token strategy being set both globally (via `CNConfig`) and individually (inside `Endpoint`), you can mix different strategies in your app!

### Event logging

CombineNetworking's CNProvider uses iOS built-in Logger (if running on iOS 14 or newer) and custom debug-mode-only logger by default for each and every request.

### Safe storage using Keychain

CombineNetworking allows you to store your access tokens in keychain. This feature is turned on by default. Using keychain to store your access keys requires you to provide keychain instance by setting value of `CNConfig.keychainInstance`.
Safe storage using keychain can be disabled by toggling `CNConfig.storeTokensInKeychain` option.

Please remember Apple's Keychain doesn't automatically remove entries created by an app upon its deletion. Do not worry, however. Only your app can access those entries. Nevertheless, if you're using CombineNetworking's safe storage, it is recommended to add some sort of app launch counter and upon first launch call `CNConfig.removeAccessToken(for endpoint: Endpoint? = nil)` to make sure any remaining old entries in keychain are removed.

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

And that's it. Enjoy :)
