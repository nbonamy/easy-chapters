//
//  ContentView.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import SwiftUI

struct ContentView: View {
  
  @State private var player: VLCPlayer!
  @ObservedObject var videoInfo = VideoInfo()
  @State private var selection = Set<UUID>()
  @State private var progress: Double = 0
  @State private var isScrobbing = false
  @State private var isEditing = false
  @State private var editedValue = ""
  @State private var videoPath = ""
  @State private var showAlert = false
  @State private var alertText = ""
  private var ffmpegPath = ""
  
  init() {
    self.ffmpegPath = Utils.findFFmpeg()
    let localInfo = VideoInfo()
    self.player = VLCPlayer(delegate: localInfo, path: videoPath)
    self.videoInfo = localInfo
  }
  
  var body: some View {
    GeometryReader { geometry in
      HStack {
        VStack {
          if (player != nil) {
            player.frame(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
          } else {
            Spacer()
          }
          Spacer().frame(height: 16)
          HStack {
            Button("Open") {
              openFilePicker()
            }
            //          Button("Play") {
            //            player.play()
            //          }
            Button(player != nil && player.isPlaying() ? "Pause" : "Play") {
              player.playpause()
            }.disabled(!videoInfo.ready)
            Button("<<") {
              player.seekby(-100)
            }.disabled(!videoInfo.ready)
              .buttonRepeatBehavior(.enabled)
            Button(">>") {
              player.seekby(100)
            }.disabled(!videoInfo.ready)
              .buttonRepeatBehavior(.enabled)
            Slider(value: $progress, onEditingChanged: { editing in
              if (isScrobbing && !editing) {
                player.seekp(progress)
              }
              isScrobbing = editing
            }).disabled(!videoInfo.ready)
            if (player != nil) {
              Text(player.timeFormatted()).monospacedDigit()
            }
          }
        }
        Spacer(minLength: 32)
        VStack {
          List(videoInfo.chapters, id: \.id, selection: $selection) { chapter in
            Text("[\(chapter.offsetFormatted)] \(chapter.name)").monospacedDigit()
              .onDoubleClick {
                player.seek(chapter.offset, resume: true)
              }
          }
          Spacer().frame(height: 16)
          HStack {
            Button("Reload") {
              player.parseChapters()
              selection.removeAll()
            }.disabled(!videoInfo.ready)
            Button("Create") {
              videoInfo.addChapter(player.time())
            }.disabled(!videoInfo.ready)
            Button("Delete") {
              for chapter in selection {
                videoInfo.deleteChapter(chapter)
              }
            }.disabled(!videoInfo.ready || selection.isEmpty)
            Button("Edit") {
              let chapter = videoInfo.getChapter(selection.first!)
              if (chapter != nil) {
                editedValue = chapter!.name
                isEditing = true
              }
            }.disabled(!videoInfo.ready || selection.count != 1)
            Button("Update Time") {
              videoInfo.updateChapterOffset(selection.first!, offset: player.time())
            }.disabled(!videoInfo.ready || selection.count != 1)
            Button("Save") {
              save()
            }.disabled(!videoInfo.ready)
          }
        }.frame(width: 400)
      }
      .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
        if (!isScrobbing && player != nil) {
          progress = player.progress()
        }
      }
      .onAppear {
        openFilePicker()
      }

      .sheet(isPresented: $isEditing) {
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
      .alert(isPresented: self.$showAlert) {
        Alert(
          title: Text("Easy Chapters"),
          message: Text(alertText),
          dismissButton: .default(Text("OK"))
        )
      }
      .padding()
    }
  }
  
  private func openFilePicker() {
    let openPanel = NSOpenPanel()
    openPanel.canChooseFiles = true
    openPanel.canChooseDirectories = false
    openPanel.allowsMultipleSelection = false
    
    if openPanel.runModal() == .OK {
      if let selectedFile = openPanel.url {
        DispatchQueue.main.async {
          if (self.player != nil) {
            self.player.stop()
          }
          self.videoPath = selectedFile.path
          self.player = VLCPlayer(delegate: videoInfo, path: videoPath)
        }
      }
    }
  }
  
  private func save() {
    
    // output path must have same extension to preserve format
    let videoExt = Utils.fileExtension(videoPath)
    let outputPath = URL(fileURLWithPath: videoPath).deletingPathExtension().appendingPathExtension(".tmp.\(videoExt)").path
    
    // write chapters file
    let chaptersPath = URL(fileURLWithPath: videoPath).appendingPathExtension("chapters").path
    do {
      let fileContents = videoInfo.ffmpegChapters()
      try fileContents.write(to: URL(fileURLWithPath: chaptersPath), atomically: true, encoding: .utf8)
    } catch {
      Utils.deleteFile(chaptersPath)
      alertText = "Error while writing chapters file"
      showAlert = true
      return
    }
    
    // FFmpeg command
    let args = [ "-y",
                 "-i", videoPath,
                 "-i", chaptersPath,
                 "-map_metadata", "1",
                 "-map_chapters", "1",
                 "-codec",  "copy",
                 outputPath
    ]
    
    let process = Process()
    let pipe = Pipe()
    
    process.launchPath = ffmpegPath
    process.arguments = args
    
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
      try process.run() // Run the command
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: .utf8) {
        print(output) // Print the output of the command
      }
      
      // delete chapters
      Utils.deleteFile(chaptersPath)
      
      // now replace file
      if Utils.deleteFile(videoPath) {
        if (Utils.renameFile(outputPath, videoPath)) {
          alertText = "Chapters updated successfully!"
          showAlert = true
        } else {
          alertText = "Error while updating output file (while renaming)"
          showAlert = true
        }
      } else {
        alertText = "Error while updating output file (while deleting)"
        showAlert = true
      }
      
    } catch {
      print("An error occurred: \(error)") // Handle errors
      alertText = "Error while updating output file (error: \(error))"
      showAlert = true
    }
    
  }
}

#Preview {
  ContentView()
}
