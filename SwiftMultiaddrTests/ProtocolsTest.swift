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

    func testProtocols() {
        do {
            let m   = try newMultiaddr("/ip4/127.0.0.1/udp/1234")
            let ps  = try m.Protocols()
            
            if ps[0].code != protocolWithName("ip4")?.code {
                XCTFail("Failed to get ip4 protocol")
            }
            if ps[1].code != protocolWithName("udp")?.code {
                XCTFail("Failed to get udp protocol")
            }
            
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testProtocolsWithGoodStrings() {
        
        let pass: [String : [String]] = [
            "/ip4"                      : ["ip4"],
            "/ip4/tcp"                  : ["ip4", "tcp"],
            "ip4/tcp/udp/ip6"           : ["ip4", "tcp", "udp", "ip6"],
            "////////ip4/tcp"           : ["ip4", "tcp"],
            "ip4/udp/////////"          : ["ip4", "udp"],
            "////////ip4/tcp////////"   : ["ip4", "tcp"]
        ]
        
        
        do {
            for (testStr, protoStrings) in pass {
                guard let ps2 = try protocolsWithString(testStr) else {
                    let errorMsg = "protocolsWithString should have succeeded" + testStr
                    XCTFail(errorMsg)
                    return
                }
                
                var i = 0
                for protoStr in protoStrings {
                    
                    let proto = ps2[i]
                    i += 1
                    
                    guard let proto2 = protocolWithName(protoStr) else {
                        let errorMsg = "Failed to create protocolWithName with" + protoStr
                        XCTFail(errorMsg)
                        return
                    }
                    
                    if proto2.code != proto.code {
                        let errorMsg = "Mismatch " + proto.name + " != " + proto2.name
                        XCTFail(errorMsg)
                        return
                    }
                }
            }
        } catch  {
            print(error)
            XCTFail()
        }
    }
    
    func testProtocolsWithBadStrings() {
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
            /// If the protocolsWithString throws we should pass the test
        }
    }
}
