import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

enum EndpointMacroError: CustomStringConvertible, Error {
    case badType, badInheritance, badOrMissingParameter
    
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

enum NetworkRequestMacroError: CustomStringConvertible, Error {
    case badType(macroName: String), badOrMissingUrlParameter, badOrMissingMethodParameter, syntaxError
    
    var description: String {
        switch self {
        case .badType(let macroName):
            return "@\(macroName)(url:) can only be applied to an EndpointBuilder"
        case .badOrMissingUrlParameter:
            return "Missing or bad parameter url passed"
        case .badOrMissingMethodParameter:
            return "Missing or bad parameter method passed"
        case .syntaxError:
            return "Unknown syntax error occurred"
        }
    }
}
 
public struct EndpointMacro: MemberMacro {
	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingMembersOf declaration: Declaration,
		in context: Context
	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw EndpointMacroError.badType
        }
        
        let structInheritedType = declaration.as(StructDeclSyntax.self)?.inheritanceClause?.inheritedTypeCollection.trimmedDescription
        let classInheritedType = declaration.as(ClassDeclSyntax.self)?.inheritanceClause?.inheritedTypeCollection.trimmedDescription
        
        guard structInheritedType == "EndpointModel" || classInheritedType == "EndpointModel" else {
            throw EndpointMacroError.badInheritance
        }
        
        guard let expression = node.argument?.as(TupleExprElementListSyntax.self)?.first?.expression,
			  let urlString = expression.as(StringLiteralExprSyntax.self)?.segments.first?.trimmedDescription,
              let _ = URL(string: VariableDetector.stripVarIndicators(from: urlString)) else {
            throw EndpointMacroError.badOrMissingParameter
		}
        
        let finalUrl = VariableDetector.detect(in: urlString)
        
		return [
        """
        let url = "\(raw: finalUrl)"
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
        let macroName = node.attributeName.trimmedDescription
        
        guard let typeDescription = declaration.as(VariableDeclSyntax.self)?.bindings.first?.typeAnnotation?.type.trimmedDescription,
              typeDescription.hasPrefix("EndpointBuilder") else {
            passedMethod = nil
            throw NetworkRequestMacroError.badType(macroName: macroName)
        }
        
        guard let expressions = node.argument?.as(TupleExprElementListSyntax.self) else {
            passedMethod = nil
            throw NetworkRequestMacroError.syntaxError
        }
        
        let segments = expressions.compactMap { $0.expression.as(StringLiteralExprSyntax.self)?.segments }
        let params = segments.compactMap { $0.trimmedDescription }
        
        guard let url = params[safe: 0], let _ = URL(string: VariableDetector.stripVarIndicators(from: url)) else {
            passedMethod = nil
            throw NetworkRequestMacroError.badOrMissingUrlParameter
        }
        
        let comparissonArray = ["get", "post", "put", "delete", "patch", "connect", "head", "options", "query", "trace"]
        
        guard params.count == 2 || (params.count == 1 && comparissonArray.contains(passedMethod ?? "")) else {
            passedMethod = nil
            throw NetworkRequestMacroError.badOrMissingMethodParameter
        }
        
        let method = passedMethod ?? params[safe: 1] ?? ""
        
        guard comparissonArray.contains(method) else {
            passedMethod = nil
            throw NetworkRequestMacroError.badOrMissingMethodParameter
        }
        
        passedMethod = nil
        let finalUrl = VariableDetector.detect(in: url)
        
        return [
            """
            get {
                .init(url: url + "\(raw: finalUrl)", method: "\(raw: method)", headers: defaultHeaders, accessTokenStrategy: defaultAccessTokenStrategy, callbackPublisher: callbackPublisher)
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
