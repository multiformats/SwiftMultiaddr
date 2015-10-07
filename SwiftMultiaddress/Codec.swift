//
//  Codec.swift
//  SwiftMultiAddress
//
//  Created by Teo on 04/10/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

enum CodecError : ErrorType {
    case InvalidMultiAddress
    case UnknownProtocol
    case NoAddress
    case ParseAddressFail
    case PortRangeFail
}

func stringToBytes(multiAddrStr: String) throws -> [UInt8]? {
    
    let tmpString = trimRight(multiAddrStr, charSet: NSCharacterSet(charactersInString: "/"))
    var protoComponents = tmpString.characters.split{$0 == "/"}.map(String.init)
    let fwSlash: Character = "/"
    
    if tmpString.characters.first != fwSlash { throw CodecError.InvalidMultiAddress }

    var bytes: [UInt8] = []
//    for proto in protoComponents {
    while protoComponents.count > 0 {
        
        let protoComponent = protoComponents.removeFirst()
        
        guard let multiAddrProtocol = protocolWithName(protoComponent) else { throw CodecError.UnknownProtocol }
        
        bytes += codeToVarint(multiAddrProtocol.code)
        
        if multiAddrProtocol.size == 0 { continue }
        
        if protoComponents.count < 1 { throw CodecError.NoAddress }
        
        let addrBytes = try addressStringToBytes(multiAddrProtocol, addrString: protoComponents.removeFirst())
        
        bytes += addrBytes!
    }
    
    return bytes
}

func addressStringToBytes(proto: Protocol, addrString: String) throws -> [UInt8]? {
    switch proto.code {
    case P_IP4:
        return try verifyIP4String(addrString)
        
    case P_TCP, P_UDP, P_DCCP, P_SCTP:
        
        guard let port = Int(addrString) else { throw CodecError.ParseAddressFail }
        
        if port > 65535 { throw CodecError.PortRangeFail }
        
        // Return the value as big-endian bytes.
        return [UInt8(port >> 8),UInt8(port & 0xff)]
        
    default:
        throw CodecError.ParseAddressFail
    }
}

/// Helper functions not available (afaik) in the Swift/Cocoa libraries.

func trimRight(theString: String, charSet: NSCharacterSet) -> String {
    
    var newString = theString
    
    while String(newString.characters.last).rangeOfCharacterFromSet(charSet) != nil {
        newString = String(newString.characters.dropLast())
    }
    
    return newString
}

enum IPParseError : ErrorType {
    case WrongSize
    case BadOctet(Int)
}

func verifyIP4String(ipAddress: String) throws -> [UInt8] {
    
    let components  = ipAddress.characters.split { $0 == "."}
    var ip: [UInt8] = []
    
    guard components.count == 4 else { throw IPParseError.WrongSize }
    
    for index in 0..<components.count {
        
        let octet = components[index]
        
        /// Check octets for range.
        guard let byte = UInt8(String(octet)) where byte >= 0 && byte <= 255 else {
            throw IPParseError.BadOctet(index+1)
        }
        ip.append(byte)
    }
    return ip
}