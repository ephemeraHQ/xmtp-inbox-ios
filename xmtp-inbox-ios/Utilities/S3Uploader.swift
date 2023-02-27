//
//  AWSUploader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/20/23.
//

import AWSClientRuntime
import AWSS3
import ClientRuntime
import Foundation

protocol Uploader {
	func upload(data: Data) async throws -> String
}

struct TestUploader: Uploader {
	var uuid = UUID()

	func upload(data _: Data) async throws -> String {
		"https://hi"
	}
}

struct S3Uploader: CredentialsProvider, Uploader {
	var uuid = UUID()

	var accessKey: String {
		Bundle.main.infoDictionary?["AWS_ACCESS_KEY_ID"] as? String ?? ""
	}

	var secretAccessKey: String {
		Bundle.main.infoDictionary?["AWS_SECRET_ACCESS_KEY_ID"] as? String ?? ""
	}

	var s3Endpoint: String {
		Bundle.main.infoDictionary?["AWS_ENDPOINT"] as? String ?? ""
	}

	var s3Region: String {
		Bundle.main.infoDictionary?["AWS_REGION"] as? String ?? ""
	}

	var s3Bucket: String {
		Bundle.main.infoDictionary?["S3_BUCKET"] as? String ?? ""
	}

	func upload(data: Data) async throws -> String {
		let config = try S3Client.S3ClientConfiguration(credentialsProvider: self, endpoint: s3Endpoint, forcePathStyle: true, region: s3Region)
		let client = S3Client(config: config)
		var input = PutObjectInput()

		input.bucket = s3Bucket
		input.key = uuid.uuidString
		input.body = ByteStream.from(data: data)

		_ = try await client.putObject(input: input)

		return "\(s3Endpoint)/\(s3Bucket)/\(uuid.uuidString)"
	}

	func getCredentials() async throws -> AWSClientRuntime.AWSCredentials {
		return AWSClientRuntime.AWSCredentials(accessKey: accessKey, secret: secretAccessKey)
	}
}
