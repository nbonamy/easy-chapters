//
//  ChapterEditor.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/29/24.
//

import SwiftUI

struct ChapterEditor: View {
  
  enum PostUpdateAction {
    case Close, Next
  }
  
  @State var editedValue: String
  var closeEditor: () -> Void
  var updateChapter: (String, PostUpdateAction) -> Chapter?
  @State private var textSelected = false

  var body: some View {
    VStack {
      
      // icon
      Spacer(minLength: 10)
      Image(nsImage: NSImage(named: "AppIcon")!)
        .resizable()
        .frame(width: 52, height: 52)
      Spacer(minLength: 26)
      
      // title
      Text("Chapter Title").bold()
      Spacer(minLength: 18)
      
      // field
      TextField("Title", text: $editedValue)
        .frame(minWidth: 225)
        .onSubmit {
          _save(PostUpdateAction.Close)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { obj in
          if let textView = obj.object as? NSTextView {
            guard !textSelected else { return }
            let range = NSRange(location: 0, length: textView.string.count)
            textView.setSelectedRange(range)
            textSelected = true
          }
        }
      
      Spacer(minLength: 16)
      
      // ok
      AlertButton("OK", prominent: true) {
        _save(PostUpdateAction.Close)
      }
      Spacer(minLength: 6)
      
      // next
      AlertButton("Next") {
        _save(PostUpdateAction.Next)
      }
      Spacer(minLength: 16)
      
      // cancel
      AlertButton("Cancel") {
        closeEditor()
      }
      
    }.padding(16).background(Color(hex: 0xDAD9D8))
  }
  
  func _save(_ action: PostUpdateAction) {
    let next = updateChapter(editedValue, action)
    editedValue = next?.name ?? ""
    textSelected = false
  }
  
  
}
