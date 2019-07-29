#!/bin/sh

# Build release version
swift build --configuration release

cp .build/release/appconsole ~/bin/appconsole
