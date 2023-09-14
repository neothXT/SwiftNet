//
//  AccessTokenStorage.swift
//
//
//  Created by Maciej Burdzicki on 15/09/2023.
//

import Foundation

extension CNConfig {
    fileprivate static var accessTokens: [String: CNAccessToken] = [:]
}

public protocol AccessTokenStorage {
    func store(_ token: CNAccessToken?, for storingLabel: String)
    func fetch(for storingLabel: String) -> CNAccessToken?
    func delete(for storingLabel: String) -> Bool
}

public class CNStorage: AccessTokenStorage {
    public func store(_ token: CNAccessToken?, for storingLabel: String) {
        guard let token = token else { return }
        guard let keychain = CNConfig.keychainInstance else {
            CNConfig.accessTokens[storingLabel] = token
            return
        }
        
        guard let data = try? token.toJsonData() else { return }
        keychain.add(data, forKey: storingLabel)
    }
    
    public func fetch(for storingLabel: String) -> CNAccessToken? {
        guard let keychain = CNConfig.keychainInstance else {
            return CNConfig.accessTokens[storingLabel]
        }
        
        guard let data = keychain.fetch(key: storingLabel) else { return nil }
        return try? JSONDecoder().decode(CNAccessToken.self, from: data)
    }
    
    public func delete(for storingLabel: String) -> Bool {
        guard let keychain = CNConfig.keychainInstance else {
            guard Array(CNConfig.accessTokens.keys).contains(storingLabel) else { return false }
            CNConfig.accessTokens.removeValue(forKey: storingLabel)
            return true
        }
        
        guard keychain.contains(key: storingLabel) else { return false }
        keychain.delete(forKey: storingLabel)
        return true
    }
}
