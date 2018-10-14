#!/bin/sh

# Updage dependencies
swift package update

# Generate a new Xcode project file
swift package generate-xcodeproj --xcconfig-overrides Package.xcconfig

# Open the newly generated Xcode project file
open appconsole.xcodeproj
