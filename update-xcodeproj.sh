#!/bin/sh

# Updage dependencies
swift package update

# Generate a new Xcode project file
swift package generate-xcodeproj

# Open the newly generated Xcode project file
open appconsole.xcodeproj
