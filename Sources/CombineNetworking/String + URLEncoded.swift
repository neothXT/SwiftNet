//
//  String + URLEncoded.swift
//  
//
//  Created by Maciej Burdzicki on 03/09/2022.
//

import Foundation

extension String {
	func encodingPlusSign() -> String {
		addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
	}
}
