Swift Multiaddr
===============

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/badge/project-multiformats-blue.svg?style=flat-square)](http://github.com/multiformats/multiformats)
[![](https://img.shields.io/badge/freenode-%23ipfs-blue.svg?style=flat-square)](http://webchat.freenode.net/?channels=%23ipfs)

> A [Multiaddr](https://github.com/multiformats/multiaddr) implementation in Swift.

## Table of Contents

- [Install](#install)
  - [Carthage](#carthage)
  - [Requirements](#requirements)
- [Usage](#usage)
- [Example](#example)
  - [Simple](#simple)
  - [Protocols](#protocols)
  - [En/decapsulate](#endecapsulate)
  - [Tunneling](#tunneling)
- [Maintainers](#maintainers)
- [Contribute](#contribute)
- [License](#license)

## Install

### Carthage

Add the following to your Cartfile
	`github "multiformats/Swiftmultiaddr"`
And in the root of your project type:
	`carthage update .`

For more information on how to install via Carthage see the [README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### Requirements

- Swift 3

## Usage

Add the SwiftMultiaddr.framework to your Xcode project:
- Select your target's `Build Phases` tab.

- Select the `Embed Frameworks`, select the Destination `Frameworks` and click the `+` to `Add Other...` buttons.

- Navigate to the Carthage/Build/Mac directory in your project root and select all the frameworks in the folder.

In your code, import SwiftMultiaddr.
## Example
### Simple
```Swift
import SwiftMultiaddr

/// This does not handle try throwing errors. You should.
/// Construct a Multiaddr from a string.
let addr = try! newMultiaddr("/ip4/127.0.0.1/udp/1234")

/// Construct a Multiaddr from bytes
let addr2 = try! newMultiaddrBytes(addr.bytes())

/// true
try! addr.string() == "/ip4/127.0.0.1/udp/1234"
try! addr.string() == addr2.string()
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
let printerOverProxy = proxy.encapsulate(printer)
/// /ip4/10.20.30.40/tcp/443/ip4/192.168.0.13/tcp/80

let proxyAgain = printerOverProxy.decapsulate(printer) 
/// /ip4/10.20.30.40/tcp/443
```

## Maintainers

Captain: [@NeoTeo](https://github.com/NeoTeo).

## Contribute

Contributions are welcome! Check out [the issues](//github.com/multiformats/SwiftMultiaddr/issues).

Check out our [contributing document](https://github.com/multiformats/multiformats/blob/master/contributing.md) for more information on how we work, and about contributing in general. Please be aware that all interactions related to multiformats are subject to the IPFS [Code of Conduct](https://github.com/ipfs/community/blob/master/code-of-conduct.md).

If editing this README, note that this README should be [standard-readme](//github.com/RichardLitt/standard-readme) compatible.

## License

[MIT](LICENSE) © [Matteo Sartori](//github.com/NeoTeo)
