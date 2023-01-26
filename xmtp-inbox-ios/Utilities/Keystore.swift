//
//  Keystore.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/17/23.
//

import Foundation
import Security
import XMTP

enum KeystoreError: Error {
    case noKeys
    case saveError(String)
    case readError(String)
    case deleteError(String)
}

struct Keystore {

    private static let addressKey = "KEY_ADDRESS"

    static func address() -> String? {
        return UserDefaults.standard.string(forKey: addressKey)
    }

    static func saveKeys(address: String, keys: PrivateKeyBundleV1) throws {
        UserDefaults.standard.set(address, forKey: addressKey)

        let keysData = try keys.serializedData()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: address,
            kSecValueData as String: keysData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == noErr else {
            throw KeystoreError.saveError("Unable to store item: \(status.description)")
        }
    }

    static func readKeys() throws -> PrivateKeyBundleV1? {
        guard let address = UserDefaults.standard.string(forKey: addressKey) else {
            return nil
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: address,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr,
           let existingItem = item as? [String: Any],
           let keysData = existingItem[kSecValueData as String] as? Data {
            return try PrivateKeyBundleV1(serializedData: keysData)
        } else {
            throw KeystoreError.readError("Keychain read failed")
        }
    }

    static func deleteKeys() throws {
        guard let address = UserDefaults.standard.string(forKey: addressKey) else {
            throw KeystoreError.noKeys
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: address
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == noErr else {
            throw KeystoreError.deleteError("Unable to delete item: \(status.description)")
        }
        UserDefaults.standard.removeObject(forKey: addressKey)
    }
}
