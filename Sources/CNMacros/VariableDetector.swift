//
//  VariableDetector.swift
//  
//
//  Created by Maciej Burdzicki on 16/06/2023.
//

import Foundation

class VariableDetector {
    static func detect(in string: String) -> String {
        string
            .replacingOccurrences(of: "${", with: #"\("#)
            .replacingOccurrences(of: "}$", with: #")"#)
    }
}
