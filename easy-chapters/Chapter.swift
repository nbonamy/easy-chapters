//
//  Chapter.swift
//  easy-chapters
//
//  Created by Nicolas Bonamy on 1/28/24.
//

import Foundation

class Chapter : Hashable, Equatable {
  var id: UUID
  var name: String
  var offset: Int
  //var duration: Int
  
  init(name: String, offset: Int, duration: Int) {
    self.id = UUID()
    self.name = name
    self.offset = offset
    //self.duration = duration
  }
  
  var offsetFormatted: String {
    get {
      return Utils.formatTime(offset)
    }
  }
  
  static func == (lhs: Chapter, rhs: Chapter) -> Bool {
    return lhs.id == rhs.id;
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id);
  }
  
}
