#!/bin/sh

# TODO: Pass in version so we're not stuck to 7.0
$XCTOOL_HOME/scripts/xctool.sh -project SSVC.xcodeproj -scheme SSVCTests -sdk iphonesimulator7.0 build test
