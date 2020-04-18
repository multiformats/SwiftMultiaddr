//
//  SwiftMultiaddressTests.swift
//  SwiftMultiaddressTests
//
//  Created by Matteo Sartori on 06/10/15.
//
//  Licensed under MIT See LICENCE file in the root of this project for details. 

import XCTest
@testable import SwiftMultiaddr

class SwiftMultiaddrTests: XCTestCase {
    func testMultiAddrConstruction() throws {
        let failCases: [String] = [
            "/ip4",
            "/ip4/::1",
            "/ip4/fdpsofodsajfdoisa",
            "/ip6",
            "/udp",
            "/tcp",
            "/sctp",
            "/udp/65536",
            "/tcp/65536",
            "/onion/9imaq4ygg2iegci7:80",
            "/onion/aaimaq4ygg2iegci7:80",
            "/onion/timaq4ygg2iegci7:0",
            "/onion/timaq4ygg2iegci7:-1",
            "/onion/timaq4ygg2iegci7",
            "/onion/timaq4ygg2iegci@:666",
            "/udp/1234/sctp",
            "/udp/1234/udt/1234",
            "/udp/1234/utp/1234",
            "/ip4/127.0.0.1/udp/jfodsajfidosajfoidsa",
            "/ip4/127.0.0.1/udp",
            "/ip4/127.0.0.1/tcp/jfodsajfidosajfoidsa",
            "/ip4/127.0.0.1/tcp",
            "/ip4/127.0.0.1/ipfs",
            "/ip4/127.0.0.1/ipfs/tcp"
        ]
        
        let passCases: [String] = [
            "/ip4/1.2.3.4",
            "/ip4/0.0.0.0",
            "/ip6/::1",
            "/ip6/2601:9:4f81:9700:803e:ca65:66e8:c21",
            "/onion/timaq4ygg2iegci7:1234",
            "/onion/timaq4ygg2iegci7:80/http",
            "/udp/0",
            "/tcp/0",
            "/sctp/0",
            "/udp/1234",
            "/tcp/1234",
            "/sctp/1234",
            "/udp/65535",
            "/tcp/65535",
            "/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC",
            "/udp/1234/sctp/1234",
            "/udp/1234/udt",
            "/udp/1234/utp",
            "/tcp/1234/http",
            "/tcp/1234/https",
            "/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234",
            "/ip4/127.0.0.1/udp/1234",
            "/ip4/127.0.0.1/udp/0",
            "/ip4/127.0.0.1/tcp/1234",
            "/ip4/127.0.0.1/tcp/1234/",
            "/ip4/127.0.0.1/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC",
            "/ip4/127.0.0.1/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234"
        ]

        try failCases.forEach {
            XCTAssertThrowsError(try Multiaddr(address: $0))
        }

        try passCases.forEach {
            XCTAssertNoThrow(try Multiaddr(address: $0))
        }
    }
    
    func testEqualityConformance() throws {
        let m1 = try Multiaddr(address: "/ip4/127.0.0.1/udp/1234")
        let m2 = try Multiaddr(address: "/ip4/127.0.0.1/tcp/1234")
        let m3 = try Multiaddr(address: "/ip4/127.0.0.1/tcp/1234")
        let m4 = try Multiaddr(address: "/ip4/127.0.0.1/tcp/1234/")

        XCTAssertNotEqual(m1, m2)
        XCTAssertEqual(m1, m1)
        XCTAssertEqual(m2, m3)
        XCTAssertEqual(m2, m4)
        XCTAssertEqual(m4, m3)
    }
    
    func testEncapsulatingWithDecapsulating() throws {
        let m = try Multiaddr(address:"/ip4/127.0.0.1/udp/1234")
        let m2 = try Multiaddr(address:"/udp/5678")

        let b = m.encapsulate(m2)
        var s = try b.string()

        XCTAssertEqual(s, "/ip4/127.0.0.1/udp/1234/udp/5678", "Encapsulate /ip4/127.0.0.1/udp/1234/udp/5678 failed " + s)

        let m3 = try Multiaddr(address:"/udp/5678")
        let c = try b.decapsulate(m3)
        s = try c.string()

        XCTAssertEqual(s, "/ip4/127.0.0.1/udp/1234", "Decapsulate /udp failed. /ip4/127.0.0.1/udp/1234" + s)

        let m4 = try Multiaddr(address:"/ip4/127.0.0.1")
        XCTAssertThrowsError(try c.decapsulate(m4))
    }
}
