//
//  IpUtilTests.swift
//  SwiftMultiaddress
//
//  Created by Matteo Sartori on 12/10/15.
//
//  Licensed under MIT See LICENCE file in the root of this project for details. 

import XCTest
@testable import SwiftMultiaddr

class IpUtilTests: XCTestCase {

    func testParseIP() {
        
        let IPTestCases: [(input: String, output: IP)] = [
            ("127.0.1.2", IPv4(127, 0, 1, 2)),
            ("127.0.0.1", IPv4(127, 0, 0, 1)),
            ("127.001.002.003", IPv4(127, 1, 2, 3)),
            ("::ffff:127.1.2.3", IPv4(127, 1, 2, 3)),
            ("::ffff:127.001.002.003", IPv4(127, 1, 2, 3)),
            ("::ffff:7f01:0203", IPv4(127, 1, 2, 3)),
            ("0:0:0:0:0000:ffff:127.1.2.3", IPv4(127, 1, 2, 3)),
            ("0:0:0:0:000000:ffff:127.1.2.3", IPv4(127, 1, 2, 3)),
            ("0:0:0:0::ffff:127.1.2.3", IPv4(127, 1, 2, 3)),
            
            ("2001:4860:0:2001::68", IP(arrayLiteral: 0x20, 0x01, 0x48, 0x60, 0, 0, 0x20, 0x01, 0, 0, 0, 0, 0, 0, 0x00, 0x68)),
            ("2001:4860:0000:2001:0000:0000:0000:0068", IP(arrayLiteral: 0x20, 0x01, 0x48, 0x60, 0, 0, 0x20, 0x01, 0, 0, 0, 0, 0, 0, 0x00, 0x68)),
            
            /// The following should fail
            ("127.0.0.256", IP()),
            ("abc", IP()),
            ("fe80::1%lo0", IP()),
            ("fe80::1%911", IP()),
            ("", IP()),
            ("a1:a2:a3:a4::b1:b2:b3:b4", IP())
        ]
        
        for testCase in IPTestCases {
            do {
                let out = try parseIP(testCase.input)
                XCTAssert(out == testCase.output)
            } catch {
                if testCase.output != IP() {
                    print("ERROR: ",error, "for test case",testCase.input)
                    XCTFail()
                }
            }
        }
    }
    
    func testEllipsis1() {
        // This is an example of a performance test case.
        let ipBytes: IP = [32,1,72,96,0,0,32,1,0,104,0,0,0,0,0,0]
        let ellipsis = 8

        self.measure {
            // Put the code you want to measure the time of here.
            try! _ = expandEllipsis(ipBytes, bytesWritten: 10, ellipsisIndex: ellipsis)
        }
    }

}
