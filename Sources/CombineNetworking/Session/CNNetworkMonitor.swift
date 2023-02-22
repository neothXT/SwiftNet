//
//  CNNetworkMonitor.swift
//  
//
//  Created by Maciej Burdzicki on 22/02/2023.
//

import Foundation
import Combine
import Reachability

public class CNNetworkMonitor {
	public static func monitorPublisher() -> AnyPublisher<Reachability.Connection, Never> {
		let reachability = try! Reachability()
		
		try? reachability.startNotifier()
		
		return NotificationCenter.default.publisher(for: .reachabilityChanged, object: reachability)
			.map { ($0.object as! Reachability).connection }
			.receive(on: DispatchQueue.main)
			.eraseToAnyPublisher()
	}
}
