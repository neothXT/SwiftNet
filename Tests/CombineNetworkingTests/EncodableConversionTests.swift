//
//  EncodableConversionTests.swift
//  
//
//  Created by Maciej Burdzicki on 24/04/2023.
//

import XCTest
@testable import CombineNetworking

final class EncodableConversionTests: XCTestCase {
	private let provider = CNProvider<RemoteEndpoint>()

	func testToDictionaryWithEmptyArray() throws {
		let model = TestParamsModelWithArray(name: "First", lastname: "Last", age: 24, array: [])
		XCTAssertFalse(model.toDictionary().contains { $0.key == "array" })
	}
	
	func testToDictionaryWithArray() throws {
		let model = TestParamsModelWithArray(name: "First", lastname: "Last", age: 24, array: ["testValue"])
		XCTAssertTrue(model.toDictionary().contains { $0.key == "array" })
	}
	
	func testToDictionaryWithEmptyDict() throws {
		let model = TestParamsModelWithDict(name: "First", lastname: "Last", age: 24, dict: [:])
		XCTAssertFalse(model.toDictionary().contains { $0.key == "dict" })
	}
	
	func testToDictionaryWithDict() throws {
		let model = TestParamsModelWithDict(name: "First", lastname: "Last", age: 24, dict: ["testKey": "testValue"])
		XCTAssertTrue(model.toDictionary().contains { $0.key == "dict" })
	}
	
	func testToDictionaryWithEmptyEnum() throws {
		let model = TestParamsModelWithEnum(name: "First", lastname: "Last", age: 24, sex: nil)
		XCTAssertFalse(model.toDictionary().contains { $0.key == "sex" })
	}
	
	func testToDictionaryWithEnum() throws {
		let model = TestParamsModelWithEnum(name: "First", lastname: "Last", age: 24, sex: .male)
		XCTAssertTrue(model.toDictionary().contains { ($0.value as? String) == "male" })
	}
	
	func testToDictionaryKeepingEmptyArray() throws {
		let model = TestParamsModelWithArray(name: "First", lastname: "Last", age: 24, array: [])
		XCTAssertTrue(model.toDictionary(options: .keepEmptyCollections).contains { $0.key == "array" })
	}
}
