//
//  ButtonSymbol.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/29/24.
//

import SwiftUI

struct ButtonSymbol: View {
  
  var symbol: String
  var action: () -> Void
  var actionShift: () -> Void
  var actionControl: () -> Void
  var actionOption: () -> Void
  var disabled: Bool
  
  static func _nop() -> Void {}
  
  init(
    _ symbol: String,
    disabled: Bool,
    action: @escaping () -> Void,
    actionShift: @escaping () -> Void = ButtonSymbol._nop,
    actionControl: @escaping () -> Void = ButtonSymbol._nop,
    actionOption: @escaping () -> Void = ButtonSymbol._nop

  ) {
    self.symbol = symbol
    self.action = action
    self.actionShift = actionShift
    self.actionControl = actionControl
    self.actionOption = actionOption
    self.disabled = disabled
  }
  
  var body: some View {
    Button {
      if CGKeyCode.shiftKeyPressed {
        actionShift()
      } else if CGKeyCode.controlKeyPressed {
        actionControl()
      } else if CGKeyCode.optionKeyPressed {
        actionOption()
      } else {
        action()
      }
    } label: {
      Image(systemName: symbol)
        .imageScale(.small)
        .foregroundColor(disabled ? .secondary.opacity(0.6) : .primary.opacity(0.7))
    }
    .buttonRepeatBehavior(.enabled)
    .disabled(disabled)
  }
}

