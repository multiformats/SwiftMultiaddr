//
//  IpUtilTests.swift
//  SwiftMultiaddress
//
//  Created by Teo on 12/10/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import XCTest
@testable import SwiftMultiaddress

class IpUtilTests: XCTestCase {

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

    func testParseIP() {
        let ip1 = "0:0:0:0:0000:ffff:127.1.2.3"
        let ip2 = "2001:4860:0:2001::68"
        var ipv6: IP = []
        self.measureBlock(){
            do {
                (ipv6, _) = try parseIPv6(ip2, zoneAllowed: false)
                (ipv6, _) = try parseIPv6(ip1, zoneAllowed: false)
            } catch {
                print(error)
                XCTFail()
            }
        }
        print(ipv6)
    }
    
    func testEllipsis1() {
        // This is an example of a performance test case.
        let ipBytes: IP = [32,1,72,96,0,0,32,1,0,104,0,0,0,0,0,0]
        let ellipsis = 8

        self.measureBlock {
            // Put the code you want to measure the time of here.
            try! expandEllipsis(ipBytes, lastEntry: 10, ellipsis: ellipsis)
        }
    }
    
    func testEllipsis2() {
        let ipBytes: IP = [32,1,72,96,0,0,32,1,0,104]
        let ellipsis = 8

        self.measureBlock {
            // Put the code you want to measure the time of here.
            try! expandEllipsis2(ipBytes, ellipsis: ellipsis)
        }

    }

}
