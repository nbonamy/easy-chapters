//
//  AlertButton.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/29/24.
//

import SwiftUI

//
// https://serialcoder.dev/text-tutorials/swiftui/handle-press-and-release-events-in-swiftui/
//

struct PressActions: ViewModifier {
  var onPress: () -> Void
  var onRelease: () -> Void
  
  func body(content: Content) -> some View {
    content
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged({ _ in
            onPress()
          })
          .onEnded({ _ in
            onRelease()
          })
      )
  }
}

extension View {
  func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
    modifier(PressActions(onPress: {
      onPress()
    }, onRelease: {
      onRelease()
    }))
  }
}

struct AlertButton: View {
  
  @State private var isPressed: Bool = false
  @State private var label: String
  @State private var action: () -> Void
  @State private var prominent: Bool
  
  init(_ label: String, prominent: Bool = false, action: @escaping () -> Void) {
    self.label = label
    self.action = action
    self.prominent = prominent
  }
  
  var body: some View {
    let b = Button(action: {
      self.isPressed = false
      self.action()
    }, label: {
      Text(label).frame(maxWidth: .infinity).frame(height: prominent ? 26 : 28)
    })
    
    if (prominent) {
      b.buttonStyle(.borderedProminent)
    } else {
      b
        .buttonStyle(.borderless)
        .foregroundColor(.black)
        .background(isPressed ? Color(hex:0xB6B8B8) : Color(hex: 0xBDBCBB))
        .cornerRadius(6)
        .pressAction {
          isPressed = true
        } onRelease: {
          isPressed = false
        }
    }
  }
}
