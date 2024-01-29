//
//  VLCPlayer.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

//
// https://github.com/denisblondeau/TestVLCKIT
//

import SwiftUI
import VLCKit

protocol VLCPlayerDelegate {
  func playerReset(_ player: VLCPlayer) -> Void
  func playerReady(_ player: VLCPlayer) -> Void
  func mediaParsed(_ player: VLCPlayer, chapters: [Chapter]) -> Void
}

/// VLC Player for SwiftUI.
struct VLCPlayer: NSViewRepresentable {
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  private let player = VLCMediaPlayer()
  private var delegate: VLCPlayerDelegate?
  private var coordinator: Coordinator?
  private var media: VLCMedia!
  @State private var _pauseAfterTimeChanged = false
  
  /// Initalise VLC Player.
  /// - Parameter url: A valid URL for the streaming media.
  init(delegate: VLCPlayerDelegate, path: String) {
    self.delegate = delegate
    self.delegate?.playerReset(self)
    if (!path.isEmpty) {
      media = VLCMedia(path: path)
      player.media = media
      player.play()
    }
  }
  
  func makeNSView(context: NSViewRepresentableContext<VLCPlayer>) -> VLCVideoView {
    let vlcView = VLCVideoView()
    player.drawable = vlcView
    
    // quit properly
    NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) {  _ in
      if player.isPlaying {
        player.stop()
      }
    }
    
    // done
    return vlcView
    
  }
  
  func updateNSView(_ vlcView: VLCVideoView, context: NSViewRepresentableContext<VLCPlayer>) -> Void {
    player.drawable = vlcView
    player.delegate = context.coordinator
    player.media?.delegate = context.coordinator
    player.libraryInstance.loggers?.append(context.coordinator)
  }
  
  func ready() -> Void {
    self.delegate?.playerReady(self)
  }
  
  func setPauseAfterTimeChanged() -> Void {
    _pauseAfterTimeChanged = true
  }
  
  func unsetPauseAfterTimeChanged() -> Void {
    _pauseAfterTimeChanged = false
  }
  
  var pauseAfterTimeChanged : Bool {
    get {
      return _pauseAfterTimeChanged
    }
  }
  
  func parseChapters() -> Void {
    var chapters = [Chapter]()
    let vlcChapters = player.chapterDescriptions(ofTitle: 0)
    for vlcChapter in vlcChapters {
      //print("\(vlcChapter)")
      if let dictChapter = vlcChapter as? [String:AnyObject] {
        let name = dictChapter["VLCChapterDescriptionName"] as? String
        let offset = dictChapter["VLCChapterDescriptionTimeOffset"] as? Int
        let duration = dictChapter["VLCChapterDescriptionDuration"] as? Int
        let chapter = Chapter(name: name!, offset: offset!, duration: duration!)
        chapters.append(chapter)
      }
    }
    print("Found \(chapters.count) chapters")
    self.delegate?.mediaParsed(self, chapters: chapters)
  }
  
  class Coordinator: NSObject, VLCLogging, VLCMediaDelegate, VLCMediaPlayerDelegate {
    
    var parent: VLCPlayer
    var level: VLCLogLevel = VLCLogLevel.error
    
    init(_ parent: VLCPlayer) {
      self.parent = parent
    }
    
    func handleMessage(_ message: String, logLevel level: VLCLogLevel, context: VLCLogContext?) -> Void {
      // Only print out errors.
      if (level == VLCLogLevel.error) {
        print("Player Error: \(message)")
      }
    }
    
    func mediaDidFinishParsing(_ aMedia: VLCMedia) -> Void {
      print("mediaDidFinishParsing")
      //print(aMedia.tracksInformation)
      parent.parseChapters()
    }
    
    func mediaMetaDataDidChange(_ aMedia: VLCMedia) -> Void {
      //print("mediaMetaDataDidChange")
      //print(aMedia.tracksInformation)
      parent.ready()
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) -> Void {
      if (parent.pauseAfterTimeChanged) {
        parent.player.pause()
        parent.unsetPauseAfterTimeChanged()
      }
    }
    
  }
}

extension VLCPlayer {
  
  func isPlaying() -> Bool {
    return player.isPlaying
  }
  
  func play() -> Void {
    if !player.isPlaying {
      player.play()
    }
  }
  
  func playpause() -> Void {
    if player.isPlaying {
      player.pause()
    } else {
      player.play()
    }
  }
  
  func stop() -> Void {
    if player.isPlaying {
      player.stop()
    }
  }
  
  func seek(_ offset: Int, resume: Bool = false) -> Void {
    let isPaused = !player.isPlaying
    if (isPaused) {
      setPauseAfterTimeChanged()
      player.play()
    }
    player.time = VLCTime(number: NSNumber(value: offset))
    if (isPaused && !resume) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        player.pause()
      }
    }
  }
  
  func seekp(_ progress: Double) -> Void {
    seek(timep(progress))
  }
  
  func seekby(_ offset: Int) -> Void {
    seek(time() + offset)
  }
  
  func time() -> Int {
    return Int(player.time.intValue)
  }
  
  func timep(_ progress: Double) -> Int {
    let offset = progress * Double(player.media?.length.intValue ?? 0)
    return Int(offset)
  }

  func timeFormatted(_ progress: Double?) -> String {
    let time = progress == nil ? time() : timep(progress!)
    return Utils.formatTime(time)
  }
  
  func duration() -> Int {
    return Int(player.media?.length.intValue ?? 0)
  }
  
  func progress() -> Double {
    return player.media == nil ? 0 : Double(time()) / Double(player.media!.length.intValue)
  }
  
  func loadChapters() -> Void {
    parseChapters()
  }
  
  func setRate(_ rate : Float) -> Void {
    player.fastForward(atRate: rate)
  }
  
  func getRate() -> Float {
    return player.rate
  }
  
}
