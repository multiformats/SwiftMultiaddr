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
        
        do {
            var ipv6 = try parseIPv6(ip2, zoneAllowed: false)
            print(ipv6)
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
