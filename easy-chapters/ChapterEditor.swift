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
      TextField("Title", text: $editedValue).frame(minWidth: 225)
      Spacer(minLength: 16)
      
      // ok
      AlertButton("OK", prominent: true) {
        _ = updateChapter(editedValue, PostUpdateAction.Close)
      }
      Spacer(minLength: 6)
      
      // next
      AlertButton("Next") {
        let next = updateChapter(editedValue, PostUpdateAction.Next)
        editedValue = next?.name ?? ""
      }
      Spacer(minLength: 16)
      
      // cancel
      AlertButton("Cancel") {
        closeEditor()
      }
      
    }.padding(16).background(Color(hex: 0xDAD9D8))
  }
  
  
}
