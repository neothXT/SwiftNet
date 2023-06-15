import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct EndpointMacro: MemberMacro {
	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingMembersOf declaration: Declaration,
		in context: Context
	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
        guard let expression = node.argument?.as(TupleExprElementListSyntax.self)?.first?.expression,
			  let urlString = expression.as(StringLiteralExprSyntax.self)?.segments.first?.trimmedDescription,
			  let _ = URL(string: urlString) else {
			//TODO throw error
			return []
		}
        
		return [
        """
        let url = \(literal: urlString)
        """
        ]
	}
}

public struct NetworkRequestMacro: AccessorMacro {
    fileprivate static var passedMethod: String?
    
    public static func expansion<Context, Declaration>(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: Declaration,
        in context: Context
    ) throws -> [AccessorDeclSyntax] where Context : MacroExpansionContext, Declaration : DeclSyntaxProtocol {
        guard let expressions = node.argument?.as(TupleExprElementListSyntax.self) else {
            //TODO throw error
            return []
        }
        
        let segments = expressions.compactMap { $0.expression.as(StringLiteralExprSyntax.self)?.segments }
        let params = segments.compactMap { $0.trimmedDescription }
        
        let comparissonArray = ["get", "post", "put", "delete", "patch", "connect", "head", "options", "query", "trace"]
        guard params.count == 2 || (params.count == 1 && comparissonArray.contains(passedMethod ?? "")) else {
            //TODO throw error
            return []
        }
        
        let method = passedMethod ?? params[safe: 1] ?? ""
        guard comparissonArray.contains(method) else {
            //TODO throw error
            return []
        }
        
        passedMethod = nil
        
        return [
            """
            get {
                .init(url: url + \(literal: params[0]), method: "\(raw: method)", headers: defaultHeaders, accessTokenStrategy: defaultAccessTokenStrategy, callbackPublisher: callbackPublisher)
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

@main
struct EndpointPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        EndpointMacro.self,
        NetworkRequestMacro.self,
        GetMacro.self,
        PostMacro.self,
        PutMacro.self,
        DeleteMacro.self,
        PatchMacro.self,
        ConnectMacro.self,
        HeadMacro.self,
        OptionsMacro.self,
        QueryMacro.self,
        TraceMacro.self
    ]
}
