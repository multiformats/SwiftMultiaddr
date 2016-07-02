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
    
    func testStringToBytes() {
        
        let testString = { (address: String, hex: String) in
            let decodedHex = try SwiftHex.decodeString(hexString: hex)
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
            let decodedHex = try SwiftHex.decodeString(hexString: hex)
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
}
