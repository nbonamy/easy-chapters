//
//  ContentView.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import SwiftUI

enum PlaybackRate {
  case Slow, Normal, Fast
}

struct ContentView: View {
  
  @State private var player: VLCPlayer!
  @State var videoInfo = VideoInfo()
  @State private var selection = Set<UUID>()
  @State private var progress: Double = 0
  @State private var isScrobbing = false
  @State private var isEditing = false
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
  
  var videoReady: Bool {
    get {
      return videoInfo.ready
    }
  }
  
  var rate: PlaybackRate {
    get {
      let rate = player.getRate()
      if rate < 0.75 {
        return PlaybackRate.Slow
      } else if rate > 1.25 {
        return PlaybackRate.Fast
      } else {
        return PlaybackRate.Normal
      }
    }
  }
  
  var rateIcon: String {
    switch rate {
    case .Slow:
      return "tortoise.fill"
    case .Fast:
      return "hare.fill"
    default:
      return "checkmark.rectangle.stack.fill"
    }
  }
  
  var body: some View {
    GeometryReader { geometry in
      HStack {
        VStack {
          if (player != nil) {
            player.cornerRadius(8).onTapGesture {
              player.playpause()
            }
          } else {
            Spacer()
          }
          Spacer().frame(height: 16)
          HStack {
            Button("Open") {
              openFilePicker()
            }
            
            ButtonSymbol("playpause.fill", disabled: !videoReady) {
              player.playpause()
            }
            
            ButtonSymbol("backward.fill", disabled: !videoReady) {
              player.seekby(-10000)
            } actionShift: {
              player.seekby(-30000)
            } actionControl: {
              player.seekby(-5000)
            }
            
            ButtonSymbol("backward.frame.fill", disabled: !videoReady) {
              player.seekby(-500)
            } actionShift: {
              player.seekby(-1000)
            } actionControl: {
              player.seekby(-100)
            }
            
            Slider(value: $progress, onEditingChanged: { editing in
              if (isScrobbing && !editing) {
                player.seekp(progress)
              }
              isScrobbing = editing
            }).disabled(!videoInfo.ready)
            
            ButtonSymbol("forward.frame.fill", disabled: !videoReady) {
              player.seekby(+500)
            } actionShift: {
              player.seekby(+1000)
            } actionControl: {
              player.seekby(+100)
            }
            
            ButtonSymbol("forward.fill", disabled: !videoReady) {
              player.seekby(+10000)
            } actionShift: {
              player.seekby(+30000)
            } actionControl: {
              player.seekby(+5000)
            }
            
            if (player != nil) {
              Text(player.timeFormatted(isScrobbing ? progress : nil)).monospacedDigit()
            }
            
            if (player != nil) {
              ButtonSymbol(rateIcon, disabled: !videoReady) {
                if rate == PlaybackRate.Normal {
                  alertText = "Hold Shift when clicking to speed up playback. Hold Control to speed down."
                  showAlert = true
                } else {
                  player.setRate(1.0)
                }
              } actionShift: {
                player.setRate(2.0)
              } actionControl: {
                player.setRate(0.5)
              }
            }
            
          }
        }
        Spacer(minLength: 16)
        VStack {
          List(videoInfo.chapters, id: \.id, selection: $selection) { chapter in
            HStack {
              Text(currentIndicator(chapter)).frame(width: 14).foregroundColor(.secondary)
              Text("[\(chapter.offsetFormatted)] \(chapter.name)").monospacedDigit()
                .onDoubleClick {
                  player.seek(chapter.offset, resume: true)
                }
            }
          }.cornerRadius(8).overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.secondary.opacity(0.4), lineWidth: 1)
          )
          Spacer().frame(height: 16)
          HStack {
            
            Button("Reload") {
              player.parseChapters()
              selection.removeAll()
            }
            .disabled(!videoReady)
            
            Button("New") {
              let chapter = videoInfo.addChapter(player.time())
              selection = [chapter.id]
            }
            .disabled(!videoReady)
            
            Button("Delete") {
              for chapter in selection {
                videoInfo.deleteChapter(chapter)
              }
              selection.removeAll()
            }
            .disabled(!videoReady || selection.isEmpty)
            
            Button("Edit") {
              isEditing = true
            }
            .disabled(!videoReady || selection.count != 1)
            
            Button("Update Time") {
              videoInfo.updateChapterOffset(selection.first!, offset: player.time())
            }
            .disabled(!videoReady || selection.count != 1)
            
            Button("Save") {
              save()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!videoReady)
            
          }
        }.frame(width: 380)
      }
      .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
        if (!isScrobbing && player != nil) {
          progress = player.progress()
        }
      }
      .sheet(isPresented: $isEditing) {
        ChapterEditor(
          editedValue: videoInfo.getChapter(selection.first!)!.name,
          closeEditor: { isEditing.toggle() },
          updateChapter: { name, action in
            
            // update
            videoInfo.updateChapterName(selection.first!, name: name)
            
            // get next
            var next : Chapter?
            if (action == ChapterEditor.PostUpdateAction.Next) {
              next = videoInfo.nextChapter(selection.first!)
            }
            if (next == nil) {
              isEditing.toggle()
              return nil
            }
            
            // switch to it
            selection = [ next!.id ]
            player.seek(next!.offset, resume: true)
            return next
            
          }
        )
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
  
  private func currentIndicator(_ chapter: Chapter) -> String {
    let current = videoInfo.currentChapter(player.time())
    return current == chapter ? "●" : ""
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
