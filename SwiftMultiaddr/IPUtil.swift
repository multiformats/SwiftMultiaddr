//
//  IPUtil.swift
//  SwiftMultiaddr
//
//  Created by Matteo Sartori on 09/10/15.
//  Licensed under MIT See LICENCE file in the root of this project for details. 
//

import Foundation

typealias IP = [UInt8]

let IPv4Len = 4
let IPv6Len = 16

enum IPError : ErrorType {
    case InvalidIPString
    case TooManyOctets
    case BadOctet(Int)
    case SeparatorInWrongPosition
    case NotEnoughRoom
    case TooManyEllipsis
    case NoEllipsisToExpand
    case NotUsedEntireString
    case UnusedEllipsis
}

let V4InV6Prefix: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0xff,0xff]

func IPv4(a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) -> IP {
    
    var outP: IP = Array<UInt8>(count: IPv6Len, repeatedValue: 0)
    outP.replaceRange(Range(0..<V4InV6Prefix.count), with: V4InV6Prefix)
    outP[12] = a
    outP[13] = b
    outP[14] = c
    outP[15] = d
    return outP
}


func firstHexString(fromString hexString: String) -> String? {
    var idx = 0
    var validHexString = hexString
    for char in hexString.utf16 {
        if validHex.characterIsMember(char) == false {
            validHexString = hexString.substringToIndex(hexString.startIndex.advancedBy(idx))
            return validHexString
        }
        idx++
    }
    return validHexString
}

func parseIP(ipString: String) throws -> IP {
    /// We decide on the IP version based on the separator.
    for char in ipString.characters {
        switch char {
        case ".":
            return try parseIPv4(ipString)
        case ":":
            let (ip, _) = try parseIPv6(ipString, zoneAllowed: false)
            return ip
        default: break
        }
    }
    throw IPError.InvalidIPString
}

func parseIPv4(ipString: String) throws -> IP {

    var ipBytes: IP = []
    let components  = ipString.characters.split { $0 == "."}
    
    guard components.count == 4 else { throw IPError.TooManyOctets }
    
    for index in 0..<components.count {
        
        let octet = components[index]
        
        /// Check octets for range.
        guard let byte = UInt8(String(octet)) where byte >= 0 && byte <= 255 else {
            throw IPError.BadOctet(index+1)
        }
        ipBytes.append(byte)
    }
    
    return IPv4(ipBytes[0], ipBytes[1], ipBytes[2], ipBytes[3])
}

func parseIPv6(ipString: String, zoneAllowed: Bool) throws -> (IP, String) {

    var ipBytes: IP         = Array<UInt8>(count: IPv6Len, repeatedValue: 0)
    var ipTmpString: String = ipString
    var zone: String        = ""
    /// We are calling two consecutive colons for ellipsis.
    var ellipsis            = -1
    var charactersRead      = 0
    
    if zoneAllowed { (ipTmpString, zone) = splitHostZone(ipTmpString) }
    
    let ipStringLength = ipTmpString.characters.count
    
    if ipStringLength >= 2 && ipString.hasPrefix("::") {
        
        ellipsis        = 0
        charactersRead  = 2
        ipTmpString = ipTmpString.substringFromIndex(ipTmpString.startIndex.advancedBy(2))
        
        if ipStringLength == charactersRead {
            return (ipBytes, zone)
        }
    }
    
    var outIndex = 0
    while outIndex < IPv6Len {
        /// Strip the front charactersRead off the ipTmpString
        guard let firstHex = firstHexString(fromString: ipTmpString) else {
            throw IPError.InvalidIPString
        }
        charactersRead += firstHex.characters.count
        guard let hexVal = Int(firstHex, radix: 16) where hexVal <= 0xffff else {
            throw IPError.InvalidIPString
        }
        
        ipTmpString = ipTmpString.substringFromIndex(ipTmpString.startIndex.advancedBy(firstHex.characters.count))
        
        var separator: Character?
        if ipTmpString.characters.count > 0 {
            separator = ipTmpString.removeAtIndex(ipTmpString.startIndex)
            charactersRead++
        }
        
        /// We might be in a trailing IPv4
        if ipTmpString.characters.count > 0 && separator == "." {

            if ellipsis < 0 && outIndex != IPv6Len-IPv4Len {
                throw IPError.SeparatorInWrongPosition
            }

            if outIndex + IPv4Len > IPv6Len {
                throw IPError.NotEnoughRoom
            }
            
            let ip4 = firstHex+String(separator!)+ipTmpString
            let ip = try parseIPv4(ip4)

            ipBytes[outIndex]   = ip[12]
            ipBytes[outIndex+1] = ip[13]
            ipBytes[outIndex+2] = ip[14]
            ipBytes[outIndex+3] = ip[15]
            charactersRead = ipStringLength
            outIndex += IPv4Len
            break
        }

        ipBytes[outIndex]   = UInt8(hexVal >> 8)
        ipBytes[outIndex+1] = UInt8(hexVal & 0xff)
        outIndex += 2
        
        /// Drop out if the string is empty.
        if ipTmpString == "" { break }
        
        // Check the first character of the next value...
        let firstChar = ipTmpString.characters.first!
        
        /// making sure it's a colon
        if separator != ":" || charactersRead+1 == ipStringLength { throw IPError.InvalidIPString }
        
        /// we need to drop out here if the next character is a colon and we haven't yet got one.
        if firstChar == ":" {
            if ellipsis >= 0 { throw IPError.TooManyEllipsis }
            ellipsis = outIndex
            
            ipTmpString.removeAtIndex(ipTmpString.startIndex)
            charactersRead++
            
            if ipTmpString.characters.count == 0 {
                break
            }
        }
    }
    
    /// Throw an error if we haven't used the whole string.
    if charactersRead != ipStringLength { throw IPError.NotUsedEntireString }
    
    /// If the ipBytes is not a full IPv6 length we need to expand it.
    if outIndex < IPv6Len {
        ipBytes = try expandEllipsis(ipBytes, bytesWritten: outIndex, ellipsisIndex: ellipsis)
    } else {
        /// At this point we've got a full output ipBytes but we still have an unexpanded
        /// ellipsis which means there's an error.
        if ellipsis >= 0 { throw IPError.UnusedEllipsis }
    }
    
    return (ipBytes,"")
}

func isZeros<N : IntegerType>(numbers: [N]) -> Bool {
    for number in numbers {
        if number != 0 { return false }
    }
    return true
}

func ipToIPv4(anIP: IP) throws -> IP {
    switch anIP.count {
    case IPv4Len:
        return anIP
    case IPv6Len where
        isZeros(Array<UInt8>(anIP[0..<10])) &&
        anIP[10] == 0xff &&
        anIP[11] == 0xff:
        
        return Array<UInt8>(anIP[12..<16])
    default:
        throw IPError.InvalidIPString
    }
}

func ipToIPv6(anIP: IP) throws -> IP {
    switch anIP.count {
    case IPv4Len:
        return IPv4(anIP[0], anIP[1], anIP[2], anIP[3])
    case IPv6Len:
        return anIP
    default:
        throw IPError.InvalidIPString
    }
}

func expandEllipsis(ipBytes: IP, bytesWritten: Int, ellipsisIndex: Int) throws -> IP {
    
    if ellipsisIndex < 0 { throw IPError.NoEllipsisToExpand }
    
    var ip  = ipBytes
    /// Calculate the number of bytes left to expand into.
    let bytesLeft   = IPv6Len - bytesWritten
    
    /// move the values after the ellipsis to the end of the output string
    for var k = bytesWritten - 1 ; k >= ellipsisIndex ; k-- {
        ip[k+bytesLeft] = ip[k]
    }
    
    /// Fill the bytes between the ellipsis and the ? with 0
    for var k = ellipsisIndex + bytesLeft - 1 ; k >= ellipsisIndex ; k-- {
        ip[k] = 0
    }
    return ip
}

func splitHostZone(ipString: String) -> (String, String) {
    
    // split the ipString at most once, effectively giving us the first
    let components  = ipString.componentsSeparatedByString("%")
    
    if components.count < 2 { return (ipString,"") }
    
    return (components.dropLast().joinWithSeparator("%"), String(components.last!))
}

let validHex = NSCharacterSet(charactersInString: "abcdefABCDEF0123456789")

/** hexStringToInt takes a hex value as a string and returns the value as an int */
func hexStringToInt(str: String) -> (Int, Int)? {
    /// First find the first non alphanumeric index.
    var idx = 0
    for char in str.utf16 {
        if validHex.characterIsMember(char) == false {
            let validHexString = str.substringToIndex(str.startIndex.advancedBy(idx))
            return (Int(validHexString, radix: 16)!,idx)
        }
        idx++
    }
    return nil
}
