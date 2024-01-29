//
//  VideoInfo.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import Foundation

@Observable class VideoInfo : VLCPlayerDelegate {
  
  var ready = false
  var chapters = [Chapter]()
  @ObservationIgnored var duration = 0

  func playerReset(_ player: VLCPlayer) -> Void {
    ready = false
    chapters.removeAll()
  }
  
  func playerReady(_ player: VLCPlayer) -> Void {
    ready = true
  }
  
  func mediaParsed(_ player: VLCPlayer, chapters: [Chapter]) -> Void {
    self.chapters = chapters
    self.duration = player.duration()
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
  
  @discardableResult
  func addChapter(_ offset: Int) -> Chapter {
    for i in 0..<chapters.count {
      if (chapters[i].offset > offset) {
        let chapter = Chapter(name: String(format: "Chapter %d", i+1), offset: offset, duration: 0);
        chapters.insert(chapter, at: i)
        return chapter;
      }
    }
    
    // append
    let chapter = Chapter(name: String(format: "Chapter %d", chapters.count+1), offset: offset, duration: 0);
    chapters.append(chapter)
    return chapter;
  }
  
  func updateChapterName(_ id: UUID, name: String) -> Void {
    let chapter = getChapter(id)
    if (chapter != nil) {
      chapter!.name = name
    }
  }
  
  func updateChapterOffset(_ id: UUID, offset: Int) -> Void {
    let chapter = getChapter(id)
    if (chapter != nil) {
      chapter!.offset = offset
      chapters.sort { $0.offset < $1.offset }
    }
  }
  
  func deleteChapter(_ id: UUID) -> Void {
    chapters.removeAll{ $0.id == id }
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


