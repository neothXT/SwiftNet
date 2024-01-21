//
//  AccessTokenStorage.swift
//
//
//  Created by Maciej Burdzicki on 15/09/2023.
//

import Foundation


extension SNConfig {
    fileprivate static var accessTokens: [String: SNAccessToken] = [:]
}

public protocol AccessTokenStorage {
    func store(_ token: SNAccessToken?, for storingLabel: String)
    func fetch(for storingLabel: String) -> SNAccessToken?
    func delete(for storingLabel: String) -> Bool
}

public class SNStorage: AccessTokenStorage {
    public func store(_ token: SNAccessToken?, for storingLabel: String) {
        guard let token = token else { return }
        guard let keychain = SNConfig.keychainInstance else {
            SNConfig.accessTokens[storingLabel] = token
            return
        }
        
        guard let data = try? token.toJsonData() else { return }
        keychain.add(data, forKey: storingLabel)
    }
    
    public func fetch(for storingLabel: String) -> SNAccessToken? {
        guard let keychain = SNConfig.keychainInstance else {
            return SNConfig.accessTokens[storingLabel]
        }
        
        guard let data = keychain.fetch(key: storingLabel) else { return nil }
        return try? JSONDecoder().decode(SNAccessToken.self, from: data)
    }
    
    public func delete(for storingLabel: String) -> Bool {
        guard let keychain = SNConfig.keychainInstance else {
            guard Array(SNConfig.accessTokens.keys).contains(storingLabel) else { return false }
            SNConfig.accessTokens.removeValue(forKey: storingLabel)
            return true
        }
        
        guard keychain.contains(key: storingLabel) else { return false }
        keychain.delete(forKey: storingLabel)
        return true
    }
}
