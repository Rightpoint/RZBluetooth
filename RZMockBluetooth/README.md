# RZMockBluetooth
These files are mock objects of the CoreBluetooth stack that quack like their CoreBluetooth equivilents. 

To fake interactions with bluetooth you can call one of the `fake` methods. These methods can be used directly in the tests to create the various responses needed to test your application. These classes can also be subclassed to provide specific device emulation for use inside your application
