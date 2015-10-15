//
//  Codec.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 04/10/15.
//
//  Licensed under MIT See LICENCE file in the root of this project for details. 

import Foundation
import Base32
import SwiftMultihash

enum CodecError : ErrorType {
    case InvalidMultiAddress
    case InvalidPortNumber
    case UnknownProtocol
    case NoAddress
    case ParseAddressFail
    case PortRangeFail
    case PortValueTooSmall
    case PortValueTooBig
    case NoPortNumber
    case NotTorOnion
    case FailedBase32Decoding
    case IPFSInconsistentLength
}

func stringToBytes(multiAddrStr: String) throws -> [UInt8] {
    
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
        return try ipToIPv4(parseIP(addrString))
        
    case P_IP6:
        return try ipToIPv6(parseIP(addrString))
        
    case P_TCP, P_UDP, P_DCCP, P_SCTP:
        
        guard let portVal = Int(addrString) else { throw CodecError.ParseAddressFail }
        
        if portVal > 65535 { throw CodecError.PortRangeFail }
        
        // Return the value as big-endian bytes.
        return [UInt8(portVal >> 8),UInt8(portVal & 0xff)]
        
    case P_ONION:
        var components = addrString.characters.split{$0 == ":"}.map(String.init)
        if components.count != 2 { throw CodecError.NoPortNumber }
        
        /// A valid tor onion address is 16 characters.
        if components[0].characters.count != 16 { throw CodecError.NotTorOnion }
        
        let onionHostBytes = components[0].uppercaseString
        guard let onionData = onionHostBytes.base32DecodedData else { throw CodecError.FailedBase32Decoding }
        var onionBytes = Array<UInt8>(count: onionData.length, repeatedValue: 0)
        onionData.getBytes(&onionBytes, length: onionData.length)
        
        /// Onion port number
        guard let portVal = Int(components[1]) else { throw CodecError.InvalidPortNumber }
        if portVal >= 65536 { throw CodecError.PortValueTooBig }
        if portVal < 1 { throw CodecError.PortValueTooSmall }

        // Return the value as big-endian bytes.
        let portBytes = [UInt8(portVal >> 8),UInt8(portVal & 0xff)]
        onionBytes += portBytes
        
        return onionBytes
        
    case P_IPFS:

        let addr = try SwiftMultihash.fromB58String(addrString)
        /// the ipfsBytes start with the size
        var ipfsBytes = codeToVarint(addr.value.count)
        ipfsBytes += addr.value
        
        return ipfsBytes
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
        
    case P_IPFS:
        
        var tmpBuffer = buffer
        let (_, bytesRead) = readVarIntCode(buffer)
        tmpBuffer = Array<UInt8>(buffer[bytesRead..<buffer.count])

        if tmpBuffer.count != bytesRead { throw CodecError.IPFSInconsistentLength }
        
        let multihash = try SwiftMultihash.cast(tmpBuffer)
        return SwiftMultihash.b58String(multihash)
        
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


