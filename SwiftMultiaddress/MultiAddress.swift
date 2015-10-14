//
//  MultiAddress.swift
//  SwiftMultiAddress
//
//  Created by Teo on 30/09/15.
//  Licensed under MIT See LICENCE for details
//

import Foundation

public struct MultiAddress {
    let raw: [UInt8]
}

public func newMultiAddr(addrString: String) throws -> MultiAddress? {
    guard let multiAddressBytes = try stringToBytes(addrString) else { return nil }
    return MultiAddress(raw: multiAddressBytes)
}