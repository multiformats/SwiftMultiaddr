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
        print("ip4")
    default:
        throw CodecError.ParseAddressFail
    }
    return nil
}

func trimRight(theString: String, charSet: NSCharacterSet) -> String {
    
    var newString = theString
    
    while String(newString.characters.last).rangeOfCharacterFromSet(charSet) != nil {
        newString = String(newString.characters.dropLast())
    }
    
    return newString
}
