# CombineNetworking
Meet CombineNetworking. Super lightweight and crazy easy to use framework to help you create and handle your network requests in a convenient way.
Besides basic network requests, CombineNetworking allows you to easily send your requests securely with a simple SSL and Certificate pinning mechanisms. But that's not all. With CombineNetworking you can also effortlessly handle authorization tokens with built-in automatic authorization mechanism.

## Installation (using CocoaPods)

`pod 'CombineNetworking'`

##### Note that in order to use CombineNetworking, your iOS Deployment Target has to be 13.0 or newer. If you code for macOS, your Deployment Target has to be 10.15 or newer.

## Key functionalities
- Sending requests easily using `Endpoint` models
- SSL and Certificate pinning with just 2 lines of code
- WebSocket connection support with `CNWebSocket`
- Secure access token storage with KeyChain (thanks to KeychainAccess framework)
- Access token storing strategy - configure `global`, `endpoint specific` (`default`) or `custom` strategy for all or just some endpoints
- Automated refresh token/callback requests

## Usage

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

`RequestMethod` is an enum with following options: `.get`, `.post`, `.put`, `.delete`.
`EndpointData` is also an enum with following options: 
- `.plain`
- `.queryParams([String: Any])`
- `.bodyParams([String: Any])` - takes `Dictionary` and parses it into `Data` to send in request's body
- `.urlEncoded([String: Any])` - takes `Dictionary` and parses it into `String` and then `Data` to send in request's body (to use with `Content-Type: application/x-www-form-urlencoded`)
- `.jsonModel(Encodable)` - similar to `.dataParams` except this one takes `Encodable` and parses it into `Data` to send in request's body

### Enable SSL and/or Certificate pinning (optional)

```Swift
//First - turn pinning on
CNConfig.pinningModes = [.ssl, .certificate]

//Second - specify certificate names (mandatory for certificate pinning, optional for ssl pinning)
CNConfig.certificateNames = ["MyCert"]

//Third - provide list of acceptable public keys (optional if you've provided certificate names)
CNConfig.SSLKeys = [myKey]
```

Please remember that for `.ssl` option it is required to provide either SSLKey or the name of a certificate attached to the project to resolve SSL public key from.

### Automatic authorization mechanism

Handling authorization callbacks with CombineNetworking is ridiculously easy. To use it with your `Endpoint` all you have to do is the following:

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
  var callbackPublisher: AnyPublisher<CNAccessToken?, Error>? {
    CNProvider<TodosEndpoint>().publisher(for: .token, responseType: CNAccessToken?.self)
  }
}
```

See? Easy peasy!

### Subscribe to a publisher

```Swift
private var subscriptions: Set<AnyCancellable> = []
var todo: Todo?

func subscribeForTodos() {
  CNProvider<TodosEndpoint>().publisher(for: .todos(1), responseType: Todo?.self)?
    .catch { (error) -> Just<Todo?> in
      print(error)
      return Just(nil)
    }
    .assign(to: \.todo, on: self)
    .store(in: &subscriptions)
}
```

And that's it. Enjoy :)
