//
//  ProtocolsTest.swift
//  SwiftMultiAddress
//
//  Created by Matteo Sartori on 05/10/15.
//
//  Licensed under MIT See LICENCE file in the root of this project for details. 

import XCTest
@testable import SwiftMultiaddr

class ProtocolsTest: XCTestCase {

    func testProtocols() throws {
        let m = try Multiaddr.newMultiaddr("/ip4/127.0.0.1/udp/1234")
        let ps = try m.protocols()

        XCTAssertEqual(ps[0].code, protocolWithName("ip4")?.code)
        XCTAssertEqual(ps[1].code, protocolWithName("udp")?.code)
    }
    
    func testProtocolsWithGoodStrings() throws {
        let pass: [String : [String]] = [
            "/ip4"                      : ["ip4"],
            "/ip4/tcp"                  : ["ip4", "tcp"],
            "ip4/tcp/udp/ip6"           : ["ip4", "tcp", "udp", "ip6"],
            "////////ip4/tcp"           : ["ip4", "tcp"],
            "ip4/udp/////////"          : ["ip4", "udp"],
            "////////ip4/tcp////////"   : ["ip4", "tcp"]
        ]
        
        for (testStr, protoStrings) in pass {
            let ps2 = try XCTUnwrap(try protocolsWithString(testStr),
                                    "protocolsWithString should have succeeded" + testStr)

            var i = 0
            for protoStr in protoStrings {

                let proto = ps2[i]
                i += 1

                let proto2 = try XCTUnwrap(protocolWithName(protoStr), "Failed to create protocolWithName with" + protoStr)
                XCTAssertEqual(proto2.code, proto.code, "Mismatch " + proto.name + " != " + proto2.name)
            }
        }
    }
    
    func testProtocolsWithBadStrings() throws {
        let fails: [String] = [
            "dsijafd",                           // bogus proto
            "/ip4/tcp/fidosafoidsa",             // bogus proto
            "////////ip4/tcp/21432141/////////", // bogus proto
            "////////ip4///////tcp/////////",    // empty protos in between
        ]

        do {
            for boguStr in fails {
                let _ = try protocolsWithString(boguStr)
                let errorMsg = "protocolsWithString should have failed with " + boguStr
                XCTFail(errorMsg)
            }
        } catch {
            // If the protocolsWithString throws we should pass the test
        }
    }
}
