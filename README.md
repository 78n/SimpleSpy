# SimpleSpy V3

SimpleSpy V3 is a penetration testing tool designed to intercept [remote calls](https://developer.roblox.com/en-us/articles/Remote-Functions-and-Events) from the client to the server.

SimpleSpy V3 is designed to be the "default" remote spy and built with minimal bloat, performance, and reliability in mind. You can find SimpleSpy V3 in places such as [Infinite Yield](https://github.com/EdgeIY/infiniteyield)

## Features
- View remotes fired
- Functioninfo spy
- Simple user interface
- Continuous support
- Included Remote-to-Script for arguments
- Improved stability and performance over alternatives
- Better Table-to-String (only use bracket notation operator with strings for keys if needed).  
  Example:
  ![table to string in action](https://github.com/RealPacket/SimpleSpy/assets/107498533/0d08ba77-7c1e-42f1-8706-e96580a2a0ca)

## Script
To use SimpleSpy V3, just run the following code (or copy the code from SimplySpy.lua) into a supported executor.
```lua
loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/RealPacket/SimpleSpy/main/SimpleSpySource.lua"))()
```

## Credits
exx for writing Simple Spy V2.2 & writing the original README.md file (which this MD file is based off of)
