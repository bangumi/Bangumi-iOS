//
//  Rating.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct ScoreInfo {
  var desc: String
  var offset: Int

  init(desc: String, offset: Int) {
    self.desc = desc
    self.offset = offset
  }
}

struct SubjectRatingView: View {
  var subject: Subject

  var collectionDesc: [String] {
    var text: [String] = []
    if let wish = subject.collection.wish {
      text.append("\(wish) 人\(CollectionType.wish.description(type: subject.type))")
    }
    if let collect = subject.collection.collect {
      text.append("\(collect) 人\(CollectionType.collect.description(type: subject.type))")
    }
    if let doing = subject.collection.doing {
      text.append("\(doing) 人\(CollectionType.do.description(type: subject.type))")
    }
    if let onHold = subject.collection.onHold {
      text.append("\(onHold) 人\(CollectionType.onHold.description(type: subject.type))")
    }
    if let dropped = subject.collection.dropped {
      text.append("\(dropped) 人\(CollectionType.dropped.description(type: subject.type))")
    }
    return text
  }

  var scoreInfo: ScoreInfo {
    if subject.rating.score >= 9.5 {
      ScoreInfo(desc: "超神作", offset: 6)
    } else if subject.rating.score >= 8.5 {
      ScoreInfo(desc: "神作", offset: 5)
    } else if subject.rating.score >= 7.5 {
      ScoreInfo(desc: "力荐", offset: 4)
    } else if subject.rating.score >= 6.5 {
      ScoreInfo(desc: "推荐", offset: 3)
    } else if subject.rating.score >= 5.5 {
      ScoreInfo(desc: "还行", offset: 2)
    } else if subject.rating.score >= 4.5 {
      ScoreInfo(desc: "较差", offset: 1)
    } else if subject.rating.score >= 3.5 {
      ScoreInfo(desc: "较差", offset: 0)
    } else {
      ScoreInfo(desc: "较差", offset: 0)
    }
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading) {
        HStack {
          Image("Musume")
            .scaleEffect(x: 0.5, y: 0.5, anchor: .bottomLeading)
            .offset(x: CGFloat(-40 * scoreInfo.offset), y: 20)
            .frame(width: 40, height: 55, alignment: .bottomLeading)
            .clipped()
          VStack(alignment: .leading) {
            HStack(alignment: .center) {
              let score = String(format: "%.1f", subject.rating.score)
              Text("\(score)").font(.title).foregroundStyle(.accent)
              if subject.rating.score > 0 {
                Text(scoreInfo.desc)
              }
            }
            if subject.rating.rank > 0 {
              HStack {
                Text("Bangumi Anime Rank:").foregroundStyle(.secondary)
                Text("#\(subject.rating.rank)")
              }
            }
          }
        }.padding(.vertical, 10)
        HStack {
          Spacer()
          Text("\(subject.rating.total) 人评分").font(.footnote)
        }
        ChartView(data: subject.rating.count, width: geometry.size.width, height: 160)
          .frame(width: geometry.size.width, height: 160)
        FlowStack {
          ForEach(collectionDesc, id: \.self) { desc in
            HStack {
              Text(desc).foregroundStyle(Color("LinkTextColor"))
              Text("/  ").foregroundStyle(.secondary)
            }.font(.footnote)
          }
        }
        Spacer()
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 20)
  }
}

struct ChartView: View {
  let data: [String: UInt]
  let width: CGFloat
  let height: CGFloat

  var show: Bool {
    if data.count == 0 {
      return false
    }
    if data.values.max() == 0 {
      return false
    }
    return true
  }

  var barWidth: CGFloat {
    if data.count == 0 {
      return 0
    }
    return (width / CGFloat(data.count)) * 0.8
  }

  var barSpacing: CGFloat {
    if data.count == 0 {
      return 0
    }
    return (width / CGFloat(data.count)) * 0.2
  }

  func barHeight(_ value: UInt) -> CGFloat {
    if let maxValue = data.values.max() {
      if maxValue == 0 {
        return 0
      }
      return height * CGFloat(value) / CGFloat(maxValue)
    }
    return 0
  }

  var body: some View {
    if show {
      HStack(alignment: .bottom, spacing: barSpacing) {
        let sorted = data.sorted { first, second -> Bool in
          first.key.localizedStandardCompare(second.key) == .orderedDescending
        }
        ForEach(sorted, id: \.key) { key, value in
          VStack {
            Spacer()
            Rectangle()
              .fill(.secondary)
              .frame(width: barWidth, height: barHeight(value))
              .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(key)
          }
        }
      }.padding(.bottom, 40)
    } else {
      HStack {
        Spacer()
        Text("暂无数据")
          .foregroundStyle(.secondary)
        Spacer()
      }
    }
  }
}

#Preview {
  SubjectRatingView(subject: .preview)
}
