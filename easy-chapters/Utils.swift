//
//  Utils.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import Foundation
import SwiftUI

extension Color {
  init(hex: Int, opacity: Double = 1.0) {
    let red = Double((hex & 0xff0000) >> 16) / 255.0
    let green = Double((hex & 0xff00) >> 8) / 255.0
    let blue = Double((hex & 0xff) >> 0) / 255.0
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
  }
}

class Utils {
  
  static func formatTime(_ time: Int) -> String {
    let hours = time / 3600000
    let minutes = (time % 3600000) / 60000
    let seconds = (time % 60000) / 1000
    let millis = time % 1000
    return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, millis)
  }
  
  @discardableResult
  static func renameFile(_ originalPath: String, _ renamedPath: String) -> Bool {
    do {
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: originalPath) {
        try fileManager.moveItem(atPath: originalPath, toPath: renamedPath)
        return true
      }
    } catch {
      print("Error renaming/moving file: \(error)")
    }
    return false
  }
  
  @discardableResult
  static func deleteFile(_ pathToDelete: String) -> Bool {
    do {
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: pathToDelete) {
        try fileManager.removeItem(atPath: pathToDelete)
      }
      return true
    } catch {
      print("Error deleting file \(pathToDelete): \(error)")
    }
    return false
  }
  
  static func fileExtension(_ filePath: String) -> String {
    let fileURL = URL(fileURLWithPath: filePath)
    return fileURL.pathExtension
  }
  
  static func which(_ binary: String) -> String {
    
    let process = Process()
    let pipe = Pipe()
    
    process.launchPath = "/usr/bin/which"
    process.arguments = [binary]
    
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
      try process.run()
      process.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let path = String(data: data, encoding: .utf8) {
        return path
      }
    } catch {
      print("Failed to locate \(binary): \(error)")
    }
    
    return ""
  }
  
  static func findFFmpeg() -> String {
    
    // find with which
    let ffmpeg = Utils.which("ffmpeg")
    if (!ffmpeg.isEmpty) {
      return ffmpeg
    }
    
    // common paths
    let commonPaths = [ "/opt/homebrew/bin/ffmpeg", "/opt/local/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg" ]
    for path in commonPaths {
      if FileManager.default.fileExists(atPath: path) {
        return path
      }
    }
    
    // too bad
    return ""
    
  }
  
}

