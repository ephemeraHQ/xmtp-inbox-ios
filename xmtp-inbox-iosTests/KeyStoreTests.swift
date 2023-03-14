//
//  KeyStoreTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/7/23.
//

import Foundation
import web3
import XCTest
import XMTP
@testable import xmtp_inbox_ios

final class KeystoreTests: XCTestCase {
	func testNoKeysByDefault() async throws {
		await Auth.signOut()
		XCTAssertEqual(nil, try Keystore.readKeys())
	}

	func testSavingKeys() throws {
		let bundleData = Data("0a86030ac00108d79e9be8e23012220a20d530eab5b9c3222b3097e9acd3c3b829d689db599882538f8809083c2ace0af41a920108d79e9be8e23012440a420a40767294d3bff40879bd3fa3aff4bbc41cf0e125674bf59422b9457614d2134e141a905ebaf4ca5d5a98f567f3549f4a40040ab032dc2126293b1d29f18138e9331a430a4104e0c3424f110602e6907a901e29ee240ed2a82ddd29803ce13f6cc9e44a6e2902801d845f8ae0e2804ac4d53765505f266fa6e4a5e2ac1994d149b57c4ed4c92512c00108ed9e9be8e23012220a20734adb910b1d680281dc7eae50197d8a5a37bff1cbc259071bffecc56c6b1ce11a920108ed9e9be8e23012440a420a404cc5e68258c9df37d81eedc6074f9bb265ce989c5452bb8eae84fe335ddbe295744780af7abb6e87395fc3adda2d1adc70fa536dd010468a92836e79e6640bfd1a430a41042f6e32f1accd1d93892dec80200cb20222eb028b4dedacef7ff9c064350ecd05d3dccf4d2ac0fba143bfe392fcf2486f5cda9f8bfa75d0fa1352ef6a913cda69".web3.bytesFromHex!)
		let bundle = try PrivateKeyBundleV1(serializedData: bundleData)
		try Keystore.saveKeys(address: "0xd05541222BC89fFE06C9BdA0ad3d1829EDdf5ddb", keys: bundle)

		// make sure we can do this twice without blowing up
		try Keystore.saveKeys(address: "0xd05541222BC89fFE06C9BdA0ad3d1829EDdf5ddb", keys: bundle)

		let fetchedKeys = try Keystore.readKeys()
		XCTAssertEqual(fetchedKeys?.identityKey, bundle.identityKey)
	}
}
