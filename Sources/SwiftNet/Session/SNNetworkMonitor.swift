//
//  SNNetworkMonitor.swift
//  
//
//  Created by Maciej Burdzicki on 22/02/2023.
//

import Foundation
import Combine
import Network

public class SNNetworkMonitor {
	private let monitor = NWPathMonitor()
	private let connectionPublisher: PassthroughSubject<ConnectionType, Never> = .init()
	
	static let shared = SNNetworkMonitor()
	
	private init() { }
	
	public func publisher() -> AnyPublisher<ConnectionType, Never> {
		monitor.pathUpdateHandler = { [unowned self] in
			if $0.status == .requiresConnection || $0.status == .unsatisfied {
				self.connectionPublisher.send(.unavailable)
			} else if $0.usesInterfaceType(.cellular) {
				self.connectionPublisher.send(.cellular)
			} else if $0.usesInterfaceType(.wifi) {
				self.connectionPublisher.send(.wifi)
			} else {
				self.connectionPublisher.send(.other)
			}
		}
		monitor.start(queue: DispatchQueue.global(qos: .background))
		return connectionPublisher.eraseToAnyPublisher()
	}
}

public extension SNNetworkMonitor {
	enum ConnectionType {
		case wifi, cellular, other, unavailable
	}
}
