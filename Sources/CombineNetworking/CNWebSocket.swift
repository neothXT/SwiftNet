//
//  CNWebSocket.swift
//  
//
//  Created by Maciej Burdzicki on 12/03/2022.
//

import Foundation
import Combine

class CNWebSocket: NSObject {
	private let webSocket: URLSessionWebSocketTask
	private var isConnected: Bool = false
	private var isConnecting: Bool = false
	private var failedToConnect: Bool = false
	
	var onConnectionEstablished: (() -> Void)?
	var onConnectionClosed: (() -> Void)?
	
	init(socket: URLSessionWebSocketTask, ignorePinning: Bool = false) {
		webSocket = socket
	}
	
	convenience init(url: URL, protocols: [String] = [], ignorePinning: Bool = false) {
		let session = CNConfig.getSession(ignorePinning: ignorePinning)
		let webSocket = protocols.count > 0 ? session.webSocketTask(with: url, protocols: protocols) : session.webSocketTask(with: url)
		self.init(socket: webSocket, ignorePinning: ignorePinning)
	}
	
	convenience init(request: URLRequest, ignorePinning: Bool = false) {
		let session = CNConfig.getSession(ignorePinning: ignorePinning)
		let webSocket = session.webSocketTask(with: request)
		self.init(socket: webSocket, ignorePinning: ignorePinning)
	}
	
	public func connect() {
		webSocket.resume()
		isConnecting = true
		ping(onSuccess: {
			[weak self] in
			self?.isConnecting = false
			self?.isConnected = true
			self?.onConnectionEstablished?()
		}) { [weak self] _ in
			self?.isConnecting = false
			self?.isConnected = false
		}
	}
	
	public func disconnect() {
		webSocket.cancel(with: .goingAway, reason: nil)
		isConnected = false
		onConnectionClosed?()
	}
	
	public func send(_ message: URLSessionWebSocketTask.Message, completion: @escaping (Error?) -> Void) {
		webSocket.send(message, completionHandler: completion)
	}
	
	public func listen(onReceive: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
		if !isConnected {
			if isConnecting {
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
					self?.listen(onReceive: onReceive)
				}
				return
			}
			
			#if DEBUG
			print("Connect to WebSocket before subscribing for messages!")
			#endif
			onReceive(.failure(CNError.notConnected))
			return
		}
		
		webSocket.receive { [weak self] in
			onReceive($0)
			self?.listen(onReceive: onReceive)
		}
	}
	
	public func ping(withTimeInterval interval: DispatchTime? = nil, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void, stopAfterError: Bool = true) {
		webSocket.sendPing { [weak self] in
			if let error = $0 {
				onError(error)
				if stopAfterError {
					return
				}
			}
			
			onSuccess?()
			
			if let interval = interval {
				DispatchQueue.main.asyncAfter(deadline: interval) { [weak self] in
					self?.ping(withTimeInterval: interval, onError: onError)
				}
			}
		}
	}
}
