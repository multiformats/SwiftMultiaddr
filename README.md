# Swift Multiaddr
A [Multiaddr](https://github.com/jbenet/multiaddr) implementation in Swift.
## Installation
#### Carthage
Add the following to your Cartfile
	github "NeoTeo/Swiftmultiaddr"
And in the root of your project type:
	carthage update .

For more information on how to install via Carthage see the [README][https://github.com/Carthage/Carthage#adding-frameworks-to-an-application]

## Usage
Add the SwiftMultiaddr.framework to your Xcode project:
- Select your target's `Build Phases` tab.

- Select the `Link Binary With Libraries`, click the `+` and then `Add Other...` buttons.

- Navigate to the Carthage/Build/Mac directory in your project root and select the SwiftMultiaddr.framework. 

In your code, import SwiftMultiaddr.
```Swift
import SwiftMultiaddr

/// This does not handle try throwing errors. You should.
/// Construct a MultiAddr from a string.
let ma1 = try! newMultiaddr("/ip4/127.0.0.1/udp/1234")

/// Construct a MultiAddr from bytes
let ma2 = newMultiAddrBytes(ma1.bytes)



## Requirements
 Swift 2

## License
MIT