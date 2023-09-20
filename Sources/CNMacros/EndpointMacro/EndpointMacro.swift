//
//  EndpointMacro.swift
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
 
public struct EndpointMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            context.diagnose(EndpointMacroError.badType.diagnostic(for: declaration))
            return []
        }
        
        let structInheritedType = declaration.as(StructDeclSyntax.self)?.inheritanceClause?.inheritedTypes.trimmedDescription
        let classInheritedType = declaration.as(ClassDeclSyntax.self)?.inheritanceClause?.inheritedTypes.trimmedDescription
        
        let structName = declaration.as(StructDeclSyntax.self)?.name.trimmedDescription
        let className = declaration.as(ClassDeclSyntax.self)?.name.trimmedDescription
        
        guard structInheritedType == "EndpointModel" || classInheritedType == "EndpointModel" else {
            context.diagnose(EndpointMacroError.badInheritance.diagnostic(for: declaration))
            return []
        }
        
        guard let endpointName = structName ?? className else {
            context.diagnose(EndpointMacroError.badType.diagnostic(for: declaration))
            return []
        }
        
        guard let expression = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
              let urlString = expression.as(StringLiteralExprSyntax.self)?.segments.first?.trimmedDescription else {
            context.diagnose(EndpointMacroError.badOrMissingParameter.diagnostic(for: declaration))
            return []
        }
        
        let finalUrl = VariableDetector.detect(in: urlString)
        
        return [
            """
            let identifier = "\(raw: endpointName)", url = "\(raw: finalUrl)"
            """
        ]
    }
}
