set -o pipefail
set -e

# "warm" iPhone 6 simulator by pre-launching it so tests don't hang
export IOS_SIMULATOR_UDID=`instruments -s devices | grep "iPhone 6 (9.3" | awk -F '[\[]' '{print $2}' | awk -F '[\]]' '{print $1}'`
open -a "simulator" --args -CurrentDeviceUDID $IOS_SIMULATOR_UDID

# Run tests on iPhone 6 simulator (64-bit)
set -o pipefail && xcodebuild test -project RZBluetooth.xcodeproj -scheme RZBluetooth -destination 'name=iPhone 6' ONLY_ACTIVE_ARCH=NO | xcpretty

# "warm" iPhone 4s simulator
export IOS_SIMULATOR_UDID=`instruments -s devices | grep "iPhone 4s (9.3" | awk -F '[\[]' '{print $2}' | awk -F '[\]]' '{print $1}'`
open -a "simulator" --args -CurrentDeviceUDID $IOS_SIMULATOR_UDID

# Run tests on iPhone 4s simulator (32-bit)
set -o pipefail && xcodebuild test -project RZBluetooth.xcodeproj -scheme RZBluetooth -destination 'name=iPhone 4s' ONLY_ACTIVE_ARCH=NO | xcpretty

