//
//  CGKeyCode.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/29/24.
//

import CoreGraphics

extension CGKeyCode
{
  // https://gist.github.com/chrispaynter/07c9b16219c3d58f57a6e2b0249db4bf
  static let kVK_RightCommand : CGKeyCode = 0x36
  static let kVK_Command      : CGKeyCode = 0x37
  static let kVK_Shift        : CGKeyCode = 0x38
  static let kVK_Option       : CGKeyCode = 0x3A
  static let kVK_Control      : CGKeyCode = 0x3B
  static let kVK_RightShift   : CGKeyCode = 0x3C
  static let kVK_RightOption  : CGKeyCode = 0x3D
  static let kVK_RightControl : CGKeyCode = 0x3E
  
  var isPressed: Bool {
    CGEventSource.keyState(.combinedSessionState, key: self)
  }
  
  static var shiftKeyPressed: Bool {
    return Self.kVK_Shift.isPressed || Self.kVK_RightShift.isPressed
  }
  
  static var controlKeyPressed: Bool {
    return Self.kVK_Control.isPressed || Self.kVK_RightControl.isPressed
  }
  
  static var optionKeyPressed: Bool {
    return Self.kVK_Option.isPressed || Self.kVK_RightOption.isPressed
  }
  
  static var commandKeyPressed: Bool {
    return Self.kVK_Command.isPressed || Self.kVK_RightCommand.isPressed
  }
}
