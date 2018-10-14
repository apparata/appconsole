#!/bin/sh

# Build release version, with explicit macOS deployment target and statically linked stdlib
swift build --configuration release -Xswiftc -static-stdlib -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.14"