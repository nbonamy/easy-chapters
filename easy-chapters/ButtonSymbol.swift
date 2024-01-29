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
  var disabled: Bool
  
  init(_ symbol: String, disabled: Bool, action: @escaping () -> Void) {
    self.symbol = symbol
    self.action = action
    self.disabled = disabled
  }
  
  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: symbol)
        .imageScale(.small)
        .foregroundColor(disabled ? .secondary.opacity(0.6) : .primary.opacity(0.7))
    }
    .buttonRepeatBehavior(.enabled)
    .disabled(disabled)
  }
}

