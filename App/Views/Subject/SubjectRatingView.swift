import Flow
import SwiftUI

struct ScoreInfo {
  var desc: String
  var offset: Int
}

struct SubjectRatingSheet: View {
  var subject: SubjectDTO

  var body: some View {
    SheetView(title: "评分分布", size: .large, closeTitle: "关闭") {
      SubjectRatingView(subject: subject)
    }
  }
}

struct SubjectRatingView: View {
  var subject: SubjectDTO

  var scoreInfo: ScoreInfo {
    let score = Int(subject.rating.score.rounded())
    let offset = score >= 4 ? Int(score - 4) : 0
    return ScoreInfo(desc: score.ratingDescription, offset: offset)
  }

  var chartData: [String: UInt] {
    var data: [String: UInt] = [:]
    for (idx, val) in subject.rating.count.enumerated() {
      data["\(idx+1)"] = UInt(val)
    }
    return data
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack {
          MusumeView(index: scoreInfo.offset, width: 40, height: 55)
          VStack(alignment: .leading) {
            HStack(alignment: .center) {
              Text("\(subject.rating.score.rateDisplay)").font(.title).foregroundStyle(.accent)
              if subject.rating.score > 0 {
                Text(scoreInfo.desc)
              }
              Spacer()
              BorderView {
                Text("\(subject.rating.total) 人评分")
                  .font(.footnote)
              }
            }
            if subject.rating.rank > 0 {
              HStack {
                Text("Bangumi \(subject.type.name.capitalized) Ranked:").foregroundStyle(
                  .secondary)
                Text("#\(subject.rating.rank)")
              }
            }
          }
        }
        GeometryReader { geometry in
          ChartView(
            title: "评分分布",
            data: chartData,
            width: geometry.size.width,
            height: 320
          )
          .frame(width: geometry.size.width, height: 320)
          .background(Color.secondary.opacity(0.02))
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(height: 320)
        HFlow(alignment: .center, spacing: 2) {
          Section {
            Text("\(subject.collection.wish)人")
            Text(CollectionType.wish.description(subject.type))
          }
          Text("/").foregroundStyle(.secondary).padding(.horizontal, 2)
          Section {
            Text("\(subject.collection.collect)人")
            Text(CollectionType.collect.description(subject.type))
          }
          Text("/").foregroundStyle(.secondary).padding(.horizontal, 2)
          Section {
            Text("\(subject.collection.doing)人")
            Text(CollectionType.doing.description(subject.type))
          }
          Text("/").foregroundStyle(.secondary).padding(.horizontal, 2)
          Section {
            Text("\(subject.collection.onHold)人")
            Text(CollectionType.onHold.description(subject.type))
          }
          Text("/").foregroundStyle(.secondary).padding(.horizontal, 2)
          Section {
            Text("\(subject.collection.dropped)人")
            Text(CollectionType.dropped.description(subject.type))
          }
        }
        .font(.footnote)
        Spacer()
      }
      .padding()
    }
  }
}
