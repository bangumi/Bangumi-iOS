//
//  RatingBox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct ScoreInfo {
  var desc: String
  var offset: Int
}

struct SubjectRatingView: View {
  let subject: Subject

  var collectionDesc: [String] {
    var text: [String] = []
    let type = subject.typeEnum
    text.append("\(subject.collection.wish) 人\(CollectionType.wish.description(type: type))")
    text.append("\(subject.collection.collect) 人\(CollectionType.collect.description(type: type))")
    text.append("\(subject.collection.doing) 人\(CollectionType.do.description(type: type))")
    text.append("\(subject.collection.onHold) 人\(CollectionType.onHold.description(type: type))")
    text.append("\(subject.collection.dropped) 人\(CollectionType.dropped.description(type: type))")
    return text
  }

  var scoreInfo: ScoreInfo {
    let score = UInt8(subject.rating.score.rounded())
    let offset = score >= 4 ? Int(score - 4) : 0
    return ScoreInfo(desc: score.ratingDescription, offset: offset)
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
              Text("\(subject.rating.score.rateDisplay)").font(.title).foregroundStyle(.accent)
              if subject.rating.score > 0 {
                Text(scoreInfo.desc)
              }
              Spacer()
              Text("\(subject.rating.total) 人评分")
                .font(.footnote)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }
            }
            if subject.rating.rank > 0 {
              HStack {
                Text("Bangumi \(subject.typeEnum.name.capitalized) Ranked:").foregroundStyle(
                  .secondary)
                Text("#\(subject.rating.rank)")
              }
            }
          }
        }.padding(.top, 10)
        ChartView(data: subject.rating.count, width: geometry.size.width, height: 150)
          .frame(width: geometry.size.width, height: 150)
          .padding(.vertical, 20)
          .background(Color.secondary.opacity(0.02))
          .clipShape(RoundedRectangle(cornerRadius: 10))
        FlowStack {
          ForEach(collectionDesc, id: \.self) { desc in
            HStack {
              Text(desc).foregroundStyle(Color("LinkTextColor"))
              Text("/  ").foregroundStyle(.secondary)
            }.font(.footnote)
          }
        }.padding(.horizontal, 8)
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
    return (width / CGFloat(data.count)) * 0.75
  }

  var barSpacing: CGFloat {
    if data.count == 0 {
      return 0
    }
    return (width / CGFloat(data.count)) * 0.15
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
              .fill(.secondary.opacity(0.8))
              .frame(width: barWidth, height: barHeight(value))
              .clipShape(RoundedRectangle(cornerRadius: 5))
            Text(key).font(.footnote)
          }
        }
      }
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
  SubjectRatingView(subject: .previewAnime)
}
