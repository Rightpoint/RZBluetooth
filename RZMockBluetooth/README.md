# RZMockBluetooth
These files are mock objects of the CoreBluetooth stack that quack like their CoreBluetooth equivilents. They only cover the CBCentralManager tree of objects, and do not implement the CBPeripheralManager trees.

To fake interactions with bluetooth you can call one of the `fake` methods. These methods can be used directly in the tests to create the various responses needed to test your application. These classes can also be subclassed to provide specific device emulation for use inside your application
