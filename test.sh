#!/bin/sh
# To run the tests for SSVC, you need to have xctool installed (https://github.com/facebook/xctool),
# and setup the XCTOOL_HOME environment variable to point to the root xctool directory, i.e.
# `export XCTOOL_HOME='/Users/tomelliott/Code/ObjectiveC/xctool'` in ~/.bashrc or ~/.base_profile

# TODO: Pass in version so we're not stuck to 8.1
$XCTOOL_HOME/scripts/xctool.sh -project SSVC.xcodeproj -scheme SSVCTests -sdk iphonesimulator8.1 build test
