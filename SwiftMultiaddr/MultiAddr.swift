//
//  MultiAddr.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 30/09/15.
//  Licensed under MIT See LICENCE for details
//

import Foundation

public struct Multiaddr {
    let raw: [UInt8]
}

public func newMultiaddr(addrString: String) throws -> Multiaddr {
    let multiaddressBytes = try stringToBytes(addrString)
    return Multiaddr(raw: multiaddressBytes)
}

public func newMultiaddrBytes(address: [UInt8]) throws -> Multiaddr {
    let addressString = try bytesToString(address)
    return try newMultiaddr(addressString)
}