//
//  MultiAddr.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 30/09/15.
//  Licensed under MIT See LICENCE for details
//

import Foundation

public struct Multiaddr: Equatable {
    public private(set) var bytes: [UInt8]

    // MARK: - Initializers
    private init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    public init(address: String) throws {
        let multiaddressBytes = try stringToBytes(address)
        self.init(bytes: multiaddressBytes)
    }

    public init(address: [UInt8]) throws {
        let addressString = try bytesToString(address)
        try self.init(address: addressString)
    }
}

extension Multiaddr {
    enum MultiaddrError: Error {
        case noSuchProtocol(code: Int)
    }

    /// Returns the string representation of a Multiaddr.
    public func string() throws -> String {
        try bytesToString(bytes)
    }
    
    public func protocols() throws -> [Protocol] {
        var ps: [Protocol] = []
        var b = bytes

        while !b.isEmpty {
            let (code, n) = readVarIntCode(b)
            guard let proto = protocolWithCode(code) else {
                throw MultiaddrError.noSuchProtocol(code: code)
            }
            
            ps.append(proto)
            b = Array(b[n..<b.count])
            
            let size = sizeForAddress(proto, buffer: b)
            b = Array(b[size..<b.count])
        }
        return ps
    }
    
    public func encapsulate(_ addr: Multiaddr) -> Multiaddr {
        Multiaddr(bytes: bytes + addr.bytes)
    }
    
    public func decapsulate(_ addr: Multiaddr) throws -> Multiaddr {
        let oldString = try string()
        let newString = try addr.string()
        guard let range = oldString.range(of: newString, options: .backwards) else {
            return Multiaddr(bytes: bytes)
        }

        return try .init(address: String(oldString[..<range.lowerBound]))
    }
}
