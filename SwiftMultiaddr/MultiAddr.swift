//
//  MultiAddr.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 30/09/15.
//  Licensed under MIT See LICENCE for details
//

import Foundation

public struct Multiaddr {
    private let bytes: [UInt8]
}

public func newMultiaddr(addrString: String) throws -> Multiaddr {
    let multiaddressBytes = try stringToBytes(addrString)
    return Multiaddr(bytes: multiaddressBytes)
}

public func newMultiaddrBytes(address: [UInt8]) throws -> Multiaddr {
    let addressString = try bytesToString(address)
    return try newMultiaddr(addressString)
}

extension Multiaddr {
    
    /// string returns the string representation of a Multiaddr
    public func string() throws -> String {
        let maString = try bytesToString(bytes)
        return maString
    }
    
    public func Protocols() throws -> [Protocol] {
        var ps: [Protocol] = []
        var b = bytes
        while b.count > 0 {
            
            let (code, n) = readVarIntCode(b)
            guard let proto = protocolWithCode(code) else {
                let error = "No protocol with code" + String(code)
                fatalError(error)
            }
            
            ps.append(proto)
            b = Array(b[n..<b.count])
            
            let size = sizeForAddress(proto, buffer: b)
            b = Array(b[size..<b.count])
        }
        return ps
    }
    
    public func encapsulate(addr: Multiaddr) -> Multiaddr {

        return Multiaddr(bytes: bytes + addr.bytes)
    }
    
    public func decapsulate(addr: Multiaddr) throws -> Multiaddr {
        
        let oldString = try string()
        let newString = try addr.string()
        guard let range = oldString.rangeOfString(newString, options: .BackwardsSearch) else {
            return Multiaddr(bytes: bytes)
        }
        let ma = try newMultiaddr(oldString.substringToIndex(range.startIndex))
        return ma
    }
}

/// Two Multiaddr are equal if their bytes are the same.
func == (lhs: Multiaddr, rhs: Multiaddr) -> Bool {
    return lhs.bytes == rhs.bytes
}