# CombineNetworking
Easy approach on Networking using Combine

### Usage

#### Create an Endpoint to work with
```Swift
enum TodosEndpoint {
  case .todos(Int)
}

extension TodosEndpoint: Endpoint {
  var baseURL: URL {
    URL(string: "https://jsonplaceholder.typicode.com/")!
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

`RequestMethod` is an enum with following options: `.get`, `.post`, `.put`, `.delete`
`EndpointData` is also an enum with following options: 
- `.plain`
- `.queryParams([String: Any])`
- `.dataParams([String: Any])` - takes `Dictionary` and parses it into `Data` to send in request's body
- `.jsonModel(Encodable)` - similar to `.dataParams` except this one takes `Encodable` and parses it into `Data` to send in request's body

#### Subscribe to provider

```Swift
private var subscriptions: Set<AnyCancellable> = []
var todo: Todo?

func subscribeForTodos() {
  CNProvider<TodosEndpoint>().publisher(for: .todos(1))?
    .catch { (error) -> Just<Todo?> in
      print(error)
      return Just(nil)
    }
    .assign(to: \.todo, on: self)
    .store(in: &subscriptions)
}
```

And that's it. Enjoy :)
