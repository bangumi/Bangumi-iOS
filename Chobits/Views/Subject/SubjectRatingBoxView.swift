//
//  SubjectRatingBoxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct ScoreInfo {
  var desc: String
  var offset: Int
}

struct SubjectRatingBoxView: View {
  let subject: Subject

  var collectionDesc: [String] {
    var text: [String] = []
    text.append(
      "\(subject.collection.wish) 人\(CollectionType.wish.description(type: subject.typeEnum))")
    text.append(
      "\(subject.collection.collect) 人\(CollectionType.collect.description(type: subject.typeEnum))"
    )
    text.append(
      "\(subject.collection.doing) 人\(CollectionType.do.description(type: subject.typeEnum))")
    text.append(
      "\(subject.collection.onHold) 人\(CollectionType.onHold.description(type: subject.typeEnum))")
    text.append(
      "\(subject.collection.dropped) 人\(CollectionType.dropped.description(type: subject.typeEnum))"
    )
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
        ChartView(
          title: "评分分布", data: subject.rating.count,
          width: geometry.size.width, height: 240
        )
        .frame(width: geometry.size.width, height: 240)
        .background(Color.secondary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        FlowStack {
          ForEach(collectionDesc, id: \.self) { desc in
            HStack {
              Text(desc)
              Text("/  ").foregroundStyle(.secondary)
            }.font(.footnote)
          }
        }.padding(.horizontal, 8)
        Spacer()
      }
    }.padding()
  }
}

#Preview {
  SubjectRatingBoxView(subject: Subject.previewAnime)
}
