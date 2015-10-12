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

func bytesToString(buffer: [UInt8]) throws -> String {
    
    var addressString = ""
    var addressBytes = buffer

    while addressBytes.count > 0 {
        
        let (code, num) = readVarIntCode(addressBytes)
        addressBytes = Array(addressBytes[num..<addressBytes.count])
        
        guard let proto = protocolWithCode(code) else { throw CodecError.UnknownProtocol }
        
        addressString += "/" + proto.name
        
        if proto.size == 0 { continue }
        
        let size = sizeForAddress(proto, buffer: addressBytes)
        let address = try addressBytesToString(proto, buffer: Array(addressBytes[0..<size]))
        if address != "" {
            addressString += "/" + address
        }
        addressBytes = Array(addressBytes[size..<addressBytes.count])
    }
    return addressString
}

func sizeForAddress(proto: Protocol, buffer: [UInt8]) -> Int {
    
    switch proto.size {
    case let s where s > 0:
        return s / 8
    case 0:
        return 0
    default:
        let (size, bytesRead) = readVarIntCode(buffer)
        return size + bytesRead
    }
}

func addressStringToBytes(proto: Protocol, addrString: String) throws -> [UInt8]? {
    switch proto.code {
    case P_IP4:
        return try verifyIP4String(addrString)
        
    case P_IP6:
        return try verifyIP6String(addrString)
        
    case P_TCP, P_UDP, P_DCCP, P_SCTP:
        
        guard let port = Int(addrString) else { throw CodecError.ParseAddressFail }
        
        if port > 65535 { throw CodecError.PortRangeFail }
        
        // Return the value as big-endian bytes.
        return [UInt8(port >> 8),UInt8(port & 0xff)]
        
    default:
        throw CodecError.ParseAddressFail
    }
}

func addressBytesToString(proto: Protocol, buffer: [UInt8]) throws -> String {
    switch proto.code {
    case P_IP4, P_IP6:
        
        return try makeIPStringFromBytes(buffer)
        
    case P_TCP, P_UDP, P_DCCP, P_SCTP:
        
        if buffer.count != 2 { throw CodecError.ParseAddressFail }
        return String(UInt16(buffer[0]) << 8 | UInt16(buffer[1]))
        
    default: break
    }
    return ""
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

protocol UIntLessThan32 : UnsignedIntegerType {}
extension UInt8 : UIntLessThan32 {}
extension UInt16: UIntLessThan32 {}

func makeIPStringFromBytes< T: UIntLessThan32>(ipBytes: [T]) throws -> String {
    
    var maxOctets = 4
    var maxVal: T = 255
    
    if ipBytes[0] is UInt16 {
        maxVal = 65535
        maxOctets = 8
    }
    
    guard ipBytes.count == maxOctets else { throw IPParseError.WrongSize }
    var ipString = ""
    
    
    for index in 0..<ipBytes.count {
        let octet = ipBytes[index]
        if octet < 0 || octet > maxVal {
            throw IPParseError.BadOctet(index+1)
        }
        
        ipString += String(octet)
        if index != maxOctets-1 { ipString += "." }
    }
    return ipString
}

//func verifyIPString< T: UIntLessThan32>(ipAddress: String) throws -> [T] {
//    
//    let components  = ipAddress.characters.split { $0 == "."}
//    var ip: [T] = []
//    var maxOctets = 4
//    var maxVal: T = 255
//    if ip[0] is UInt16 {
//        maxOctets = 8
//        maxVal = 65535
//    }
//    guard components.count == maxOctets else { throw IPParseError.WrongSize }
//    
//    for index in 0..<components.count {
//        
//        let octet: T = String(components[index]) as! T
//
//        /// Check octets for range.
//        if octet < 0 || octet > maxVal {
//            throw IPParseError.BadOctet(index+1)
//        }
//        ip.append(octet)
//    }
//    return ip
//}
func verifyIP6String(ipAddress: String) throws -> [UInt8] {
    var ip: [UInt8] = []
    return ip
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

