#!/bin/sh

# Build for macOS with explicit deployment target
swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.14"
