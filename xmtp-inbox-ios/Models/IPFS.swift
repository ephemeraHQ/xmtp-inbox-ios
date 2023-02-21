//
//  IPFS.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/20/23.
//

import CryptoKit
import Foundation

struct IPFSUploadResponse: Codable {
	let name, hash, size: String

	enum CodingKeys: String, CodingKey {
		case name = "Name"
		case hash = "Hash"
		case size = "Size"
	}
}

enum IPFSError: Error {
	case pinError(String)
}

struct IPFS {
	static let shared = IPFS()
	var url: URL

	private init() {
		let username = Bundle.main.infoDictionary?["IPFS_INFURA_KEY"] as? String ?? ""
		let password = Bundle.main.infoDictionary?["IPFS_INFURA_SECRET_KEY"] as? String ?? ""

		guard let url = URL(string: "https://\(username):\(password)@ipfs.infura.io:5001") else {
			fatalError("Could not get ipfs url")
		}

		self.url = url
	}

	func get(_ cid: String) async throws -> Data? {
		let url = url.appendingPathComponent("/api/v0/cat").appending(queryItems: [
			URLQueryItem(name: "arg", value: cid),
		])

		print("GETTING \(cid)")

		var request = URLRequest(url: url)
		request.httpMethod = "POST"

		let (downloadedURL, response) = try await URLSession.shared.download(for: request)
		let data = try Data(contentsOf: downloadedURL)
		print("RESPONSE: \(response)")

		print("Hash of downloaded data: \(SHA256.hash(data: data).description)")
		print("DATA: \(data)")
		print("DATA AS STRING: \(String(data: data, encoding: .utf8))")

		// TODO: Just move the file instead of reading and writing the data
		return data
	}

	// swiftlint:disable force_unwrapping
	func upload(filename: String, data attachmentData: Data) async throws -> IPFSUploadResponse? {
		let url = url.appendingPathComponent("/api/v0/add")

		// generate boundary string using a unique per-app string
		let boundary = UUID().uuidString

		let session = URLSession.shared

		// Set the URLRequest to POST and to the specified URL
		var request = URLRequest(url: url)

		// Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
		// And the boundary is also set here
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

		var data = Data()

		// Add the image data to the raw http request data
		data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
		data.append("Content-Disposition: form-data; name=\"\("file")\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
		data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
		data.append(attachmentData)
		data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

		request.httpMethod = "POST"

		let responseData = try await session.upload(for: request, from: data).0
		let decoder = JSONDecoder()

		return try decoder.decode(IPFSUploadResponse.self, from: responseData)
	}
}
