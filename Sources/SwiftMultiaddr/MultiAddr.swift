//
//  MultiAddr.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 30/09/15.
//  Licensed under MIT See LICENCE for details
//

import Foundation

public struct Multiaddr {
    let _bytes: [UInt8]
}

public func newMultiaddr(_ addrString: String) throws -> Multiaddr {
    let multiaddressBytes = try stringToBytes(addrString)
    return Multiaddr(_bytes: multiaddressBytes)
}

public func newMultiaddrBytes(_ address: [UInt8]) throws -> Multiaddr {
    let addressString = try bytesToString(address)
    return try newMultiaddr(addressString)
}

extension Multiaddr {
    
    public func bytes() -> [UInt8] {
        return _bytes
    }
    
    /// string returns the string representation of a Multiaddr
    public func string() throws -> String {
        let maString = try bytesToString(_bytes)
        return maString
    }
    
    public func Protocols() throws -> [Protocol] {
        var ps: [Protocol] = []
        var b = _bytes
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
    
    public func encapsulate(_ addr: Multiaddr) -> Multiaddr {

        return Multiaddr(_bytes: _bytes + addr._bytes)
    }
    
    public func decapsulate(_ addr: Multiaddr) throws -> Multiaddr {
        
        let oldString = try string()
        let newString = try addr.string()
        guard let range = oldString.range(of: newString, options: .backwards) else {
            return Multiaddr(_bytes: _bytes)
        }
        let ma = try newMultiaddr(oldString.substring(to: range.lowerBound))
        return ma
    }
}

/// Two Multiaddr are equal if their bytes are the same.
public func == (lhs: Multiaddr, rhs: Multiaddr) -> Bool {
    return lhs._bytes == rhs._bytes
}
