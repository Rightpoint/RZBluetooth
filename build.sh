# Run tests on iPhone 6 simulator (64-bit)
set -o pipefail && xcodebuild build-for-testing test-without-building -project RZBluetooth.xcodeproj -scheme RZBluetooth -destination 'name=iPhone 6' ONLY_ACTIVE_ARCH=NO | xcpretty

# Run tests on iPhone 4s simulator (32-bit)
set -o pipefail && xcodebuild clean build-for-testing test-without-building -project RZBluetooth.xcodeproj -scheme RZBluetooth -destination 'name=iPhone 4s' ONLY_ACTIVE_ARCH=NO | xcpretty

