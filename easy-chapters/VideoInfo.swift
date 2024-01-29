//
//  VideoInfo.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import Foundation

class VideoInfo : ObservableObject, VLCPlayerDelegate {
  
  var chapters = [Chapter]()
  var duration = 0
  var ready = false
  
  func playerReset(_ player: VLCPlayer) {
    ready = false
    chapters.removeAll()
    self.objectWillChange.send()
  }
  
  func playerReady(_ player: VLCPlayer) {
    ready = true
    self.objectWillChange.send()
  }
  
  func mediaParsed(_ player: VLCPlayer, chapters: [Chapter]) {
    self.chapters = chapters
    self.duration = player.duration()
    self.objectWillChange.send()
  }
  
  func getChapter(_ id : UUID) -> Chapter? {
    return chapters.first { $0.id == id }
  }
  
  func nextChapter(_ id : UUID) -> Chapter? {
    for i in 0..<chapters.count-1 {
      if chapters[i].id == id {
        return chapters[i+1]
      }
    }
    return nil
  }
  
  @discardableResult func addChapter(_ offset: Int) -> Chapter {
    for i in 0..<chapters.count {
      if (chapters[i].offset > offset) {
        let chapter = Chapter(name: String(format: "Chapter %d", i+1), offset: offset, duration: 0);
        chapters.insert(chapter, at: i)
        self.objectWillChange.send()
        return chapter;
      }
    }
    
    // append
    let chapter = Chapter(name: String(format: "Chapter %d", chapters.count+1), offset: offset, duration: 0);
    chapters.append(chapter)
    self.objectWillChange.send()
    return chapter;
  }
  
  func updateChapterName(_ id: UUID, name: String) {
    let chapter = getChapter(id)
    if (chapter != nil) {
      chapter!.name = name
      self.objectWillChange.send()
    }
  }
  
  func updateChapterOffset(_ id: UUID, offset: Int) {
    let chapter = getChapter(id)
    if (chapter != nil) {
      chapter!.offset = offset
      chapters.sort { $0.offset < $1.offset }
      self.objectWillChange.send()
    }
  }
  
  func deleteChapter(_ id: UUID) {
    chapters.removeAll{ $0.id == id }
    self.objectWillChange.send()
  }
  
  func ffmpegChapters() -> String {
    var lines = [String]()
    lines.append(";FFMETADATA1")
    for i in 0..<chapters.count {
      let chapter = chapters[i]
      let end = (i == chapters.count - 1) ? duration : chapters[i+1].offset
      lines.append("[CHAPTER]")
      lines.append("TIMEBASE=1/1000")
      lines.append("START=\(chapter.offset)")
      lines.append("END=\(end)")
      lines.append("title=\(chapter.name.trimmingCharacters(in: [" "]))")
    }
    return lines.joined(separator: "\n")
  }
}


