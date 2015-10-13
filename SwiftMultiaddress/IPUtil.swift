//
//  IPUtil.swift
//  SwiftMultiaddress
//
//  Created by Teo on 09/10/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//  Licensed under MIT See LICENCE file in the root of this project for details. 
//

import Foundation

typealias IP = [UInt8]

let IPv4Len = 4
let IPv6Len = 16

//func parseIP(ipString: String) -> IP {
//
//    /// We decide on the IP version based on the separator. 
//    if (ipString.rangeOfString(".") != nil) {
//        return parseIPv4
//    }
//    
//}
enum IPError : ErrorType {
    case InvalidIPString
    case TooManyOctets
    case BadOctet(Int)
    case SeparatorInWrongPosition
    case NotEnoughRoom
    case TooManyEllipsis
    case EllipsisFail
    case NotUsedEntireString
}

let V4InV6Prefix: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0xff,0xff]

func IPv4(a: UInt8, b: UInt8, c: UInt8, d: UInt8) -> IP {
    
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
    print("IPv4")
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
    
    return IPv4(ipBytes[0], b: ipBytes[1], c: ipBytes[2], d: ipBytes[3])
}

func parseIPv6(ipString: String, zoneAllowed: Bool) throws -> (IP, String) {
    print("IPv6")
    var ipBytes: IP = []
    var ipTmpString: String = ipString
    var zone: String = ""
    var ellipsis = -1
    var charactersRead = 0
    
    if zoneAllowed { (ipTmpString, zone) = splitHostZone(ipTmpString) }
    
    let ipStringLength = ipTmpString.characters.count
    
    if ipStringLength >= 2 && ipString.hasPrefix("::") {
        ellipsis = 0
        charactersRead = 2
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
            ipTmpString.removeAtIndex(ipTmpString.startIndex)
        }
        
        /// We might be in a trailing IPv4
        if ipTmpString.characters.count > 0 && separator == "." {
            print("ellipsis",ellipsis,"outIndex",outIndex)
            if ellipsis < 0 && outIndex != IPv6Len-IPv4Len {
                throw IPError.SeparatorInWrongPosition
            }
            if ipBytes.count + IPv4Len > IPv6Len {
                throw IPError.NotEnoughRoom
            }
            
            let ip4 = firstHex+String(separator)+ipTmpString
            let ip = try parseIPv4(ip4)
            
            ipBytes.append(ip[12])
            ipBytes.append(ip[13])
            ipBytes.append(ip[14])
            ipBytes.append(ip[15])
            charactersRead = ipStringLength
            outIndex += IPv4Len // remove this when sure it's the same as ipBytes.count
            break
        }
        
        ipBytes.append(UInt8(hexVal >> 8))
        ipBytes.append(UInt8(hexVal & 0xff))
        outIndex += 2 // remove this when sure it's the same as ipBytes.count
        
        if ipTmpString == "" {
            break
        }
        separator = ipTmpString.characters.first!
        /// we need to drop out here if the next character is an ellipsis and we haven't yet got one.
        if separator == ":" {
            if ellipsis >= 0 { throw IPError.TooManyEllipsis }
            ellipsis = ipBytes.count
         
            ipTmpString.removeAtIndex(ipTmpString.startIndex)
            charactersRead++
            if ipTmpString.characters.count == 0 {
                break
            }
        }
    }
    
    /// Throw an error if we haven't used the whole string.
    if ipTmpString != ""{ throw IPError.NotUsedEntireString }
    
    /// If the ipBytes is not a full IPv6 length we need to expand it.
    if ipBytes.count < IPv6Len {
        ipBytes = try expandEllipsis(ipBytes, ellipsis: ellipsis)
    }
    
    return (ipBytes,"")
}

func expandEllipsis(ipBytes: IP, ellipsis: Int) throws -> IP {
    if ellipsis < 0 { throw IPError.EllipsisFail }
    
    let j = ipBytes.count
    var ip: IP = Array<UInt8>(count: IPv6Len, repeatedValue: 0)
    ip.replaceRange(Range(0..<ipBytes.count), with: ipBytes)

    let n = IPv6Len - j
    for var k = j - 1 ; k >= ellipsis ; k-- {
        ip[k+n] = ip[k]
    }
    for var k = ellipsis + n - 1 ; k >= ellipsis ; k-- {
        ip[k] = 0
    }
    return ip
}

func expandEllipsis2(ipBytes: IP, ellipsis: Int) throws -> IP {
    var ip = ipBytes
    if ip.count < IPv6Len {
        if ellipsis < 0 { throw IPError.EllipsisFail }
        /// store the bytes after the ellipsis
        let sub = ip[ellipsis..<ip.count]
        /// remove the bytes after the ellipsis
        ip = IP(ip[0..<ellipsis])
        /// expand the empty bytes
        let zBytes = Array<UInt8>(count: IPv6Len-ellipsis-sub.count, repeatedValue: 0)
        /// rebuild the final expanded IPv6 string.
        ip = ip+zBytes+sub
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
