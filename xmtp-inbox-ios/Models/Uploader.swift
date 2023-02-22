//
//  Uploader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/20/23.
//

import AWSClientRuntime
import AWSS3
import ClientRuntime
import Foundation

struct RemoteAttachmentUploader: CredentialsProvider {
	var uuid = UUID()
	var data: Data

	func upload() async throws -> String {
		let config = try S3Client.S3ClientConfiguration(credentialsProvider: self, endpoint: "https://s3.us-west-1.wasabisys.com", forcePathStyle: true, region: "us-west-1")
		let client = S3Client(config: config)
		var input = PutObjectInput()
		input.bucket = "remote-attachment-proof-of-concept"
		input.key = uuid.uuidString
		input.body = ByteStream.from(data: data)

		let response = try! await client.putObject(input: input)

		return "https://s3.us-west-1.wasabisys.com/remote-attachment-proof-of-concept/\(uuid.uuidString)"
	}

	func getCredentials() async throws -> AWSClientRuntime.AWSCredentials {
		let key = Bundle.main.infoDictionary?["AWS_ACCESS_KEY_ID"] as? String ?? ""
		let secret = Bundle.main.infoDictionary?["AWS_SECRET_ACCESS_KEY_ID"] as? String ?? ""

		return AWSClientRuntime.AWSCredentials(accessKey: key, secret: secret)
	}
}
