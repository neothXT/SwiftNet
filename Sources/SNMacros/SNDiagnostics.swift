//
//  SNDiagnostics.swift
//
//
//  Created by Maciej Burdzicki on 18/06/2023.
//

import Foundation
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder

enum EndpointMacroError: SNDiagnostics, CustomStringConvertible, Error {
    case badType, badInheritance, badOrMissingParameter
    
    var domain: String { "endpoint" }
    
    var description: String {
        switch self {
        case .badType:
            return "@Endpoint(url:) can only be applied to a struct or a class"
        case .badInheritance:
            return "@Endpoint(url:) can only be applied to a struct or a class which implements EndpointModel protocol"
        case .badOrMissingParameter:
            return "Missing or bad parameter url passed"
        }
    }
}

enum NetworkRequestMacroError: SNDiagnostics, CustomStringConvertible, Error {
    case typeNotRecognized, badType(macroName: String), badOrMissingUrlParameter, badOrMissingMethodParameter, syntaxError
    
    var domain: String { "network request" }
    
    var description: String {
        switch self {
        case .typeNotRecognized:
            return "Type couldn't be recognized"
        case .badType(let macroName):
            return "@\(macroName)(url:) can only be applied to an EndpointBuilder"
        case .badOrMissingUrlParameter:
            return "Bad or missing url parameter passed"
        case .badOrMissingMethodParameter:
            return "Bad or missing method parameter passed"
        case .syntaxError:
            return "Unknown syntax error occurred"
        }
    }
}

protocol SNDiagnostics {
    var domain: String { get }
    var description: String { get }
    func diagnostic(for node: SyntaxProtocol, severity: DiagnosticSeverity, fixIts: [FixIt]) -> Diagnostic
}

extension SNDiagnostics {
    func diagnostic(for node: SyntaxProtocol, severity: DiagnosticSeverity = .error, fixIts: [FixIt] = []) -> Diagnostic {
        .init(
            node: Syntax(node),
            message: SNDiagnosticMessage(
                diagnosticID: .init(domain: domain,id: String(describing: self)),
                message: description, severity: severity),
            fixIts: fixIts)
    }
}

struct FixItMsg: FixItMessage {
    var fixItID: MessageID
    var message: String
}

fileprivate struct SNDiagnosticMessage: DiagnosticMessage {
    var diagnosticID: MessageID
    var message: String
    var severity: DiagnosticSeverity
}
