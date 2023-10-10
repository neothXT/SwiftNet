//
//  File.swift
//  
//
//  Created by Maciej Burdzicki on 06/09/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation
 
public struct NetworkRequestMacro: AccessorMacro {
    fileprivate static var passedMethod: String?
    
    public static func expansion<Context, Declaration>(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: Declaration,
        in context: Context
    ) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        let macroName = node.attributeName.trimmedDescription
        
        guard let declarationType = declaration.as(VariableDeclSyntax.self)?.bindings.first?.typeAnnotation?.type else {
            context.diagnose(NetworkRequestMacroError.typeNotRecognized.diagnostic(for: declaration))
            return []
        }
        
        guard declarationType.trimmedDescription.hasPrefix("EndpointBuilder") else {
            passedMethod = nil
            let expectedType = "EndpointBuilder<\(declarationType.trimmedDescription)>"
            let typeFixIt = FixIt.Change.replace(
                oldNode: Syntax(declarationType),
                newNode: Syntax(
                    TypeSyntax(stringLiteral: expectedType)
                )
            )
            let fixit = FixIt(
                message: FixItMsg(fixItID: .init(domain: "network request", id: "typeError"), message: "Did you mean to use '\(expectedType)'?"),
                changes: [typeFixIt]
            )
            
            context.diagnose(NetworkRequestMacroError.badType(macroName: macroName).diagnostic(for: declaration, fixIts: [fixit]))
            return []
        }
        
        guard let expressions = node.arguments?.as(LabeledExprListSyntax.self) else {
            passedMethod = nil
            context.diagnose(NetworkRequestMacroError.syntaxError.diagnostic(for: declaration))
            return []
        }
        
        let segments = expressions.compactMap { $0.expression.as(StringLiteralExprSyntax.self)?.segments }
        let params = segments.compactMap { $0.trimmedDescription }
        
        guard let url = params[safe: 0] else {
            passedMethod = nil
            context.diagnose(NetworkRequestMacroError.badOrMissingUrlParameter.diagnostic(for: declaration))
            return []
        }
        
        let comparissonArray = ["get", "post", "put", "delete", "patch", "connect", "head", "options", "query", "trace"]
        
        guard let method = params[safe: 1] ?? passedMethod, comparissonArray.contains(method) else {
            passedMethod = nil
            context.diagnose(NetworkRequestMacroError.badOrMissingMethodParameter.diagnostic(for: declaration))
            return []
        }
        
        let descriptorExpression = expressions.first { $0.label?.text == "descriptor" }
        var descriptor = descriptorExpression?.expression.description ?? params[safe: 2] ?? params[safe: 1] ?? ".init()"
        
        // In case if method was mistaken for descriptor, correct it with default descriptor
        if comparissonArray.contains(descriptor) {
            descriptor = ".init()"
        }
        
        passedMethod = nil
        let finalUrl = VariableDetector.detect(in: url)
        
        return [
            """
            get {
                .init(
                    url: url + "\(raw: finalUrl)",
                    method: "\(raw: method)", 
                    descriptor: \(raw: descriptor),
                    identifier: identifier
                )
            }
            """
        ]
    }
}

public struct GetMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "get"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct PostMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "post"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct PutMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "put"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct DeleteMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "delete"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct PatchMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "patch"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct ConnectMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "connect"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct HeadMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "head"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct OptionsMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "options"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct QueryMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "query"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

public struct TraceMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(of node: AttributeSyntax, providingAccessorsOf declaration: Declaration, in context: Context) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        NetworkRequestMacro.passedMethod = "trace"
        return try NetworkRequestMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

fileprivate extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
