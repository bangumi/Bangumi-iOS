//
//  Rating.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectRatingView: View {
  var subject: Subject

  var collectionDesc: String {
    var text = ""
    if let wish = subject.collection.wish {
      text += "\(wish) 人\(CollectionType.wish.description(type: subject.type))"
      text += " / "
    }
    if let collect = subject.collection.collect {
      text += "\(collect) 人\(CollectionType.collect.description(type: subject.type))"
      text += " / "
    }
    if let doing = subject.collection.doing {
      text += "\(doing) 人\(CollectionType.do.description(type: subject.type))"
      text += " / "
    }
    if let onHold = subject.collection.onHold {
      text += "\(onHold) 人\(CollectionType.onHold.description(type: subject.type))"
      text += " / "
    }
    if let dropped = subject.collection.dropped {
      text += "\(dropped) 人\(CollectionType.dropped.description(type: subject.type))"
    }
    return text
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("\(subject.rating.total) 人评分")
      Text(collectionDesc)
      if subject.rating.rank > 0 {
        Text("Bangumi 排名 \(subject.rating.rank)")
      }
      if subject.rating.score > 0 {
        let score = String(format: "%.1f", subject.rating.score)
        Text("评分 \(score)")
      }
    }
  }
}
