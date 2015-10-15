//
//  CodecTests.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 05/10/15.
//
//  Licensed under MIT See LICENCE file in the root of this project for details. 

import XCTest
@testable import SwiftMultiaddr
import SwiftHex

class CodecTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testStringToBytes() {
        
        let testString = { (address: String, hex: String) in
            let decodedHex = try SwiftHex.decodeString(hex)
            let encodedAddress = try stringToBytes(address)
            
            XCTAssert(decodedHex == encodedAddress)
        }
    
        
        do {
            try testString("/ip4/127.0.0.1/udp/1234", "047f0000011104d2")
            try testString("/ip4/127.0.0.1/tcp/4321", "047f0000010610e1")
            try testString("/ip4/127.0.0.1/udp/1234/ip4/127.0.0.1/tcp/4321", "047f0000011104d2047f0000010610e1")
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testBytesToString() {
        
        let testString = { (address: String, hex: String) in
            let decodedHex = try SwiftHex.decodeString(hex)
            let encodedAddress = try bytesToString(decodedHex)
            
            XCTAssert(address == encodedAddress)
        }
        
        
        do {
            try testString("/ip4/127.0.0.1/udp/1234", "047f0000011104d2")
            try testString("/ip4/127.0.0.1/tcp/4321", "047f0000010610e1")
            try testString("/ip4/127.0.0.1/udp/1234/ip4/127.0.0.1/tcp/4321", "047f0000011104d2047f0000010610e1")
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testAddressStringToBytes() {
        print("testAddressStringToBytes")
    }
}
