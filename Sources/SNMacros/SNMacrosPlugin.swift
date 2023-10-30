import SwiftCompilerPlugin
import SwiftSyntaxMacros
 
@main
struct SNMacrosPlugin: CompilerPlugin {
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
