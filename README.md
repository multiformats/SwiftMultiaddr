Swift Multiaddr
===============

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

> A [Multiaddr](https://github.com/jbenet/multiaddr) implementation in Swift.

## Installation
#### Carthage
Add the following to your Cartfile
	`github "NeoTeo/Swiftmultiaddr"`
And in the root of your project type:
	`carthage update .`

As of v0.4.1 of the Base32 framework, if you are running Swift 2.1, it is necessary to run the `carthage update --no-use-binaries` to ensure that the Base32 is recompiled using the same Swift version as the rest.

For more information on how to install via Carthage see the [README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

## Usage
Add the SwiftMultiaddr.framework to your Xcode project:
- Select your target's `Build Phases` tab.

- Select the `Link Binary With Libraries`, click the `+` and then `Add Other...` buttons.

- Navigate to the Carthage/Build/Mac directory in your project root and select the SwiftMultiaddr.framework. 

In your code, import SwiftMultiaddr.
## Example
### Simple
```Swift
import SwiftMultiaddr

/// This does not handle try throwing errors. You should.
/// Construct a MultiAddr from a string.
let addr = try! newMultiaddr("/ip4/127.0.0.1/udp/1234")

/// Construct a MultiAddr from bytes
let addr2 = try! newMultiaddrBytes(addr.bytes())

/// true
addr.string() == "/ip4/127.0.0.1/udp/1234"
addr.string() == addr2.string()
addr.bytes() == addr2.bytes()
addr == addr2
```

### Protocols
```Swift
/// Assuming the previous addr exists
addr.protocols()
/// [SwiftMultiaddr.Protocol(
///		code: 4, size: 32, name: "ip4", vCode: [4]), 
///SwiftMultiaddr.Protocol(
///		code: 17, size: 16, name: "udp", vCode: [17])] 
```

### En/decapsulate
```Swift
try! addr.encapsulate(newMultiaddr("/sctp/5678"))
/// Returns a SwiftMultiaddr /ip4/127.0.0.1/udp/1234/sctp/5678
try! addr.decapsulate(newMultiaddr("/udp/1234"))
/// Returns a SwiftMultiaddr /ip4/127.0.0.1
```

### Tunneling
Multiaddr allows expressing tunnels in a very readable fashion.
```Swift
let printer = try! newMultiaddr("/ip4/192.168.0.13/tcp/80")
let proxy   = try! newMultiaddr("/ip4/10.20.30.40/tcp/443")
let printerOverProxy = try! proxy.encapsulate(printer)
/// /ip4/10.20.30.40/tcp/443/ip4/192.168.0.13/tcp/80

let proxyAgain = try! printerOverProxy.decapsulate(printer) 
/// /ip4/10.20.30.40/tcp/443
```
## Requirements
 Swift 2

## License
MIT