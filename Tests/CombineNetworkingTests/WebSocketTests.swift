import XCTest
import Combine
@testable import CombineNetworking

final class WebSocketTests: XCTestCase {
	func testWebSocketConnection() throws {
		let expectation = expectation(description: "Establish WebSocket connection")
		
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		webSocket.onConnectionEstablished = {
			webSocket.disconnect()
			expectation.fulfill()
		}
		
		webSocket.connect()
		wait(for: [expectation], timeout: 10)
	}
	
	func testWebSoketSendMessage() throws {
		let expectation = expectation(description: "Establish WebSocket connection and send a message")
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		webSocket.connect()
		webSocket.send(.string("Test message")) {
			if let _ = $0 {
				return
			}
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testWebSocketReceiveMessage() throws {
		let expectation = expectation(description: "Establish WebSocket connection and receive a message")
		
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		let receiverWebSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		receiverWebSocket.connect()
		receiverWebSocket.listen { result in
			switch result {
			case .success:
				receiverWebSocket.disconnect()
				expectation.fulfill()
			default:
				return
			}
		}
		
		webSocket.connect()
		webSocket.send(.string("Test message"), completion: { _ in webSocket.disconnect() })
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testWebSocketReconnect() throws {
		let expectation = expectation(description: "Reestablish WebSocket connection and receive a message")
		
		let webSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		let receiverWebSocket = CNWebSocket(url: URL(string: "wss://socketsbay.com/wss/v2/2/demo/")!)
		receiverWebSocket.connect()
		receiverWebSocket.disconnect()
		receiverWebSocket.reconnect()
		receiverWebSocket.listen { result in
			switch result {
			case .success:
				receiverWebSocket.disconnect()
				expectation.fulfill()
			default:
				return
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
			webSocket.connect()
			webSocket.send(.string("Test message"), completion: { _ in webSocket.disconnect() })
		}
		
		wait(for: [expectation], timeout: 30)
	}
}
