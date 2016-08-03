//
//  Protocols.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 30/09/15.
//  Licensed under MIT See LICENCE for details
//

import Foundation
import VarInt

public struct Protocol {
    let code: Int
    let size: Int
    let name: String
    let vCode: [UInt8]
}

let
P_IP4   = 4,
P_TCP   = 6,
P_UDP   = 17,
P_DCCP  = 33,
P_IP6   = 41,
P_SCTP  = 132,
P_UTP   = 301,
P_UDT   = 302,
P_IPFS  = 421,
P_HTTP  = 480,
P_HTTPS = 443,
P_ONION = 444

let lengthPrefixedVarSize = -1

/** A case for using enums instead?
enum Protocols {
    case IP_4(Int,String,[UInt8]) // nah, they're all the same...
}
*/
let Protocols = [
    Protocol(code: P_IP4,   size:  32, name: "ip4",   vCode: codeToVarint(P_IP4)),
    Protocol(code: P_TCP,   size:  16, name: "tcp",   vCode: codeToVarint(P_TCP)),
    Protocol(code: P_UDP,   size:  16, name: "udp",   vCode: codeToVarint(P_UDP)),
    Protocol(code: P_DCCP,  size:  16, name: "dccp",  vCode: codeToVarint(P_DCCP)),
    Protocol(code: P_IP6,   size: 128, name: "ip6",   vCode: codeToVarint(P_IP6)),
    /// These require varint:
    Protocol(code: P_SCTP,  size:  16, name: "sctp",  vCode: codeToVarint(P_SCTP)),
    Protocol(code: P_ONION, size:  80, name: "onion", vCode: codeToVarint(P_ONION)),
    Protocol(code: P_UTP,   size:   0, name: "utp",   vCode: codeToVarint(P_UTP)),
    Protocol(code: P_UDT,   size:   0, name: "udt",   vCode: codeToVarint(P_UDT)),
    Protocol(code: P_HTTP,  size:   0, name: "http",  vCode: codeToVarint(P_HTTP)),
    Protocol(code: P_HTTPS, size:   0, name: "https", vCode: codeToVarint(P_HTTPS)),
    Protocol(code: P_IPFS,  size: lengthPrefixedVarSize, name: "ipfs", vCode: codeToVarint(P_IPFS))
]

enum ProtocolErrors : Error {
    case notFound
}

func protocolWithName(_ name: String) -> Protocol? {
    for pcol in Protocols {
        if pcol.name == name { return pcol }
    }
    return nil
}

func protocolWithCode(_ code: Int) -> Protocol? {
    for pcol in Protocols {
        if pcol.code == code { return pcol }
    }
    return nil
}

func protocolsWithString(_ string: String) throws -> [Protocol]? {
    
    let trimmedString = string.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let splitString = trimmedString.characters.split{$0 == "/"}.map(String.init)
    
    if splitString.count != 0 {
        
        var foundProtocols: [Protocol] = []
        for protoName in splitString {
            
            guard let p = protocolWithName(protoName) else { throw ProtocolErrors.notFound }
            
            foundProtocols.append(p)
        }
        
        return foundProtocols
    }
    return nil
}

func codeToVarint(_ num: Int) -> [UInt8] {
    let buf = putUVarInt(UInt64(num))
    let bufsiz = buf.count

    return Array(buf[0..<bufsiz])
}

func varIntToCode(_ buffer: [UInt8]) -> (Int, Int) {
    return readVarIntCode(buffer)
}

func readVarIntCode(_ buffer: [UInt8]) -> (Int, Int) {
    let (value, bytesRead) = uVarInt(buffer)
    if bytesRead < 0 { fatalError("varints larger than uint64 not currently supported") }
    return (Int(value), bytesRead)
}
