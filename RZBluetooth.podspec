# -*- coding: utf-8 -*-
Pod::Spec.new do |s|
  s.name         = "RZBluetooth"
  s.version      = "0.1"
  s.summary      = "A Core Bluetooth helper library to simplify the development and testing of Core Bluetooth applications."

  s.description  = <<-DESC
                   DESC

  s.homepage     = "http://github.com/Raizlabs/RZBluetooth"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Brian King" => "brianaking@gmail.com" }
  s.platform     = :ios, 7.0
  s.source       = { :git => "https://github.com/Raizlabs/RZBluetooth.git", :tag => "0.1" }
  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec "Core" do |core|
    core.source_files = "RZBluetooth/**/*.{h,m}"
    core.public_header_files = "RZBluetooth/**/*.h"
  end

  s.subspec "RZMockBluetooth" do |fryolator|
    fryolator.dependency "RZBluetooth/Core"
    fryolator.source_files = "RZMockBluetooth/**/*.{h,m}"
    fryolator.public_header_files = "RZMockBluetooth/**/*.h"
  end
end
