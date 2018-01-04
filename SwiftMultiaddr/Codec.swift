//
//  Codec.swift
//  SwiftMultiAddr
//
//  Created by Matteo Sartori on 04/10/15.
//
//  Licensed under MIT See LICENCE file in the root of this project for details. 

import Foundation
//import Base32
import SwiftMultihash

enum CodecError : Error {
    case invalidMultiAddress
    case invalidPortNumber
    case unknownProtocol
    case noAddress
    case parseAddressFail
    case portRangeFail
    case portValueTooSmall
    case portValueTooBig
    case noPortNumber
    case notTorOnion
    case failedBase32Decoding
    case ipfsInconsistentLength
}

func stringToBytes(_ multiAddrStr: String) throws -> [UInt8] {
    
    let tmpString = trimRight(multiAddrStr, charSet: CharacterSet(charactersIn: "/"))
    var protoComponents = tmpString.characters.split{$0 == "/"}.map(String.init)
    let fwSlash: Character = "/"
    
    if tmpString.characters.first != fwSlash { throw CodecError.invalidMultiAddress }

    var bytes: [UInt8] = []
//    for proto in protoComponents {
    while protoComponents.count > 0 {
        
        let protoComponent = protoComponents.removeFirst()
        
        guard let multiAddrProtocol = protocolWithName(protoComponent) else { throw CodecError.unknownProtocol }
        
        bytes += codeToVarint(multiAddrProtocol.code)
        
        if multiAddrProtocol.size == 0 { continue }
        
        if protoComponents.count < 1 { throw CodecError.noAddress }
        
        let addrBytes = try addressStringToBytes(multiAddrProtocol, addrString: protoComponents.removeFirst())
        
        bytes += addrBytes!
    }
    
    return bytes
}

func bytesToString(_ buffer: [UInt8]) throws -> String {
    
    var addressString = ""
    var addressBytes = buffer

    while addressBytes.count > 0 {
        
        let (code, num) = readVarIntCode(addressBytes)
        addressBytes = Array(addressBytes[num..<addressBytes.count])
        
        guard let proto = protocolWithCode(code) else { throw CodecError.unknownProtocol }
        
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

func sizeForAddress(_ proto: Protocol, buffer: [UInt8]) -> Int {
    
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

func addressStringToBytes(_ proto: Protocol, addrString: String) throws -> [UInt8]? {
    switch proto.code {
    case P_IP4:
        return try ipToIPv4(parseIP(addrString))
        
    case P_IP6:
        return try ipToIPv6(parseIP(addrString))
        
    case P_TCP, P_UDP, P_DCCP, P_SCTP:
        
        guard let portVal = Int(addrString) else { throw CodecError.parseAddressFail }
        
        if portVal > 65535 { throw CodecError.portRangeFail }
        
        // Return the value as big-endian bytes.
        return [UInt8(portVal >> 8),UInt8(portVal & 0xff)]
        
    case P_ONION:
        var components = addrString.characters.split{$0 == ":"}.map(String.init)
        if components.count != 2 { throw CodecError.noPortNumber }
        
        /// A valid tor onion address is 16 characters.
        if components[0].characters.count != 16 { throw CodecError.notTorOnion }
        
        let onionHostBytes = components[0].uppercased()
//        guard let onionData = onionHostBytes.base32DecodedData else { throw CodecError.failedBase32Decoding }
		guard let onionData = Base32Decode(onionHostBytes) else { throw CodecError.failedBase32Decoding }
        var onionBytes = Array<UInt8>(repeating: 0, count: onionData.count)
//        onionData.getBytes(&onionBytes, length: onionData.length)
		onionData.copyBytes(to: &onionBytes, count: onionData.count)
		
        /// Onion port number
        guard let portVal = Int(components[1]) else { throw CodecError.invalidPortNumber }
        if portVal >= 65536 { throw CodecError.portValueTooBig }
        if portVal < 1 { throw CodecError.portValueTooSmall }

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
        throw CodecError.parseAddressFail
    }
}

func addressBytesToString(_ proto: Protocol, buffer: [UInt8]) throws -> String {
    switch proto.code {
    case P_IP4, P_IP6:
        
        return try makeIPStringFromBytes(buffer)
        
    case P_TCP, P_UDP, P_DCCP, P_SCTP:
        
        if buffer.count != 2 { throw CodecError.parseAddressFail }
        return String(UInt16(buffer[0]) << 8 | UInt16(buffer[1]))
        
    case P_IPFS:
        
        var tmpBuffer = buffer
        let (size, bytesRead) = readVarIntCode(buffer)
        tmpBuffer = Array<UInt8>(buffer[bytesRead..<buffer.count])

        if tmpBuffer.count != size { throw CodecError.ipfsInconsistentLength }
        
        let multihash = try SwiftMultihash.cast(tmpBuffer)
        return SwiftMultihash.b58String(multihash)
        
    default: break
    }
    return ""
}

/// Helper functions not available (afaik) in the Swift/Cocoa libraries.

func trimRight(_ theString: String, charSet: CharacterSet) -> String {
    
    var newString = theString
    
    while String(describing: newString.characters.last).rangeOfCharacter(from: charSet) != nil {
        newString = String(newString.characters.dropLast())
    }
    
    return newString
}

enum IPParseError : Error {
    case wrongSize
    case badOctet(Int)
}

protocol UIntLessThan32 : UnsignedInteger {}
extension UInt8 : UIntLessThan32 {}
extension UInt16: UIntLessThan32 {}

func makeIPStringFromBytes< T: UIntLessThan32>(_ ipBytes: [T]) throws -> String {
    
    var maxOctets = 4
    var maxVal: T = 255
    
    if ipBytes[0] is UInt16 {
        maxVal = 65535
        maxOctets = 8
    }
    
    guard ipBytes.count == maxOctets else { throw IPParseError.wrongSize }
    var ipString = ""
    
    
    for index in 0..<ipBytes.count {
        let octet = ipBytes[index]
        if octet < 0 || octet > maxVal {
            throw IPParseError.badOctet(index+1)
        }
        
        ipString += String(describing: octet)
        if index != maxOctets-1 { ipString += "." }
    }
    return ipString
}


