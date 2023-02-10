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

enum Keystore {
	private static let addressKey = "KEY_ADDRESS"

	static func address() -> String? {
		return AppGroup.defaults.string(forKey: addressKey)
	}

	private static func accountName() -> String? {
		guard let address = address() else {
			return nil
		}
		return "\(Constants.xmtpEnv):\(address)"
	}

	static func saveKeys(address: String, keys: PrivateKeyBundleV1) throws {
		AppGroup.defaults.set(address, forKey: addressKey)

		guard let accountName = accountName() else {
			return
		}

		AppGroup.keychain[data: accountName] = try keys.serializedData()
	}

	static func readKeys() throws -> PrivateKeyBundleV1? {
		guard let accountName = accountName() else {
			return nil
		}

		if let keysData = try AppGroup.keychain.getData(accountName) {
			return try PrivateKeyBundleV1(serializedData: keysData)
		} else {
			return nil
		}
	}

	static func deleteKeys() throws {
		guard let accountName = accountName() else {
			return
		}

		try AppGroup.keychain.remove(accountName)
		AppGroup.defaults.removeObject(forKey: addressKey)
	}
}
