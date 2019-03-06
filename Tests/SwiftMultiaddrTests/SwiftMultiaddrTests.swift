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
        
    func testMultiAddrConstruction() {
    
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
        
        
        /// First we test for cases that need to fail the construction to pass the test
        for testCase in failCases {
            do {
                try _ = newMultiaddr(testCase)
                XCTFail("The constructor should have failed.")
            } catch {}
        }
        
        for testCase in passCases {
            do {
                let multiaddress = try newMultiaddr(testCase)
                print(multiaddress)
                
                
            } catch {
                print("Error:",error)
                XCTFail("The constructor should have succeeded.")
            }
        }
    }
    
    func testEqual() {
        do {
            let m1 = try newMultiaddr("/ip4/127.0.0.1/udp/1234")
            let m2 = try newMultiaddr("/ip4/127.0.0.1/tcp/1234")
            let m3 = try newMultiaddr("/ip4/127.0.0.1/tcp/1234")
            let m4 = try newMultiaddr("/ip4/127.0.0.1/tcp/1234/")
            
            if m1 == m2     { XCTFail("Should not be equal") }
            if m2 == m1     { XCTFail("Should not be equal") }
            if !(m2 == m3)  { XCTFail("Should be equal") }
            if !(m3 == m2)  { XCTFail("Should be equal") }
            if !(m1 == m1)  { XCTFail("Should be equal") }
            if !(m2 == m4)  { XCTFail("Should be equal") }
            if !(m4 == m3)  { XCTFail("Should be equal") }
            
        } catch {
            XCTFail("constructor failed!")
        }
    }
    
    func testEnDecapsulate() {
        do {
            let m   = try newMultiaddr("/ip4/127.0.0.1/udp/1234")
            let m2  = try newMultiaddr("/udp/5678")
            
            let b   = m.encapsulate(m2)
            var s   = try b.string()
            
            if s != "/ip4/127.0.0.1/udp/1234/udp/5678" {
                let eMsg = "Encapsulate /ip4/127.0.0.1/udp/1234/udp/5678 failed " + s
                XCTFail(eMsg)
            }
            
            
            let m3  = try newMultiaddr("/udp/5678")
            let c   = try b.decapsulate(m3)
            s       = try c.string()
            
            if s != "/ip4/127.0.0.1/udp/1234" {
                let eMsg = "Decapsulate /udp failed. /ip4/127.0.0.1/udp/1234" + s
                XCTFail(eMsg)
            }
            
            
            /** Here decapsulate will throw because it will attempt to create a
             empty Multiaddr and fail. Failing this is correct and passes the
             test by dropping into the empty catch./Volumes/HAL/music/Bram.Stokers.Dracula.1CD.1992.OST.[WmC]
             */
            let m4  = try newMultiaddr("/ip4/127.0.0.1")
            do {
                let d   = try c.decapsulate(m4)
                s       = try d.string()
                let eMsg = "Decapsulate /ip4 failed. /"
                XCTFail(eMsg)
            } catch {}
            
        } catch {
            print(error)
            XCTFail()
        }
    }
}
