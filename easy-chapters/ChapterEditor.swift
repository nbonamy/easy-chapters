//
//  ChapterEditor.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/29/24.
//

import SwiftUI

struct ChapterEditor: View {
  
  @Binding var videoInfo: VideoInfo
  @Binding var isEditing: Bool
  @Binding var selection: Set<UUID>
  @Binding var editedValue: String
  
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
        videoInfo.updateChapterName(selection.first!, name: editedValue)
        isEditing.toggle()
      }
      Spacer(minLength: 6)
      
      // next
      AlertButton("Next") {
        let id = selection.first!
        videoInfo.updateChapterName(id, name: editedValue)
        let next = videoInfo.nextChapter(id)
        if next != nil {
          selection.removeAll()
          selection.insert(next!.id)
          editedValue = next!.name
        } else {
          isEditing.toggle()
        }
      }
      Spacer(minLength: 16)
      
      // cancel
      AlertButton("Cancel") {
        isEditing.toggle()
      }
      
    }.padding(16).background(Color(hex: 0xDAD9D8))
  }
  
  
}
