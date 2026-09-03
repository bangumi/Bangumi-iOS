import Flow
import SwiftUI

struct GlassSubjectRatingSheet: View {
  let subject: SubjectDTO

  @Environment(\.theme) private var theme

  private let chartHeight: CGFloat = 220

  private var scoreInfo: ScoreInfo {
    let score = Int(subject.rating.score.rounded())
    let offset = score >= 4 ? Int(score - 4) : 0
    return ScoreInfo(desc: score.ratingDescription, offset: offset)
  }

  private var chartData: [String: UInt] {
    var data: [String: UInt] = [:]
    for (idx, val) in subject.rating.count.enumerated() {
      data["\(idx+1)"] = UInt(val)
    }
    return data
  }

  private var collectStats: String {
    let parts: [String] = [
      "\(subject.collection.wish) \(CollectionType.wish.description(subject.type))",
      "\(subject.collection.collect) \(CollectionType.collect.description(subject.type))",
      "\(subject.collection.doing) \(CollectionType.doing.description(subject.type))",
      "\(subject.collection.onHold) \(CollectionType.onHold.description(subject.type))",
      "\(subject.collection.dropped) \(CollectionType.dropped.description(subject.type))",
    ]
    return parts.joined(separator: " · ")
  }

  var body: some View {
    SheetView(title: "评分分布", size: .height(468), closeTitle: "关闭") {
      ScrollView {
        VStack(alignment: .leading, spacing: GlassForm.blockSpacing) {
          header
          CardView(padding: theme.metrics.cardPadding) {
            GeometryReader { geometry in
              ChartView(
                title: "评分分布",
                data: chartData,
                width: geometry.size.width,
                height: chartHeight
              )
              .frame(width: geometry.size.width, height: chartHeight)
            }
            .frame(height: chartHeight)
          }
          Text(collectStats)
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(theme.tertiaryText)
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.top, GlassForm.topInset)
        .padding(.bottom, theme.metrics.screenPadding)
      }
    }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 12) {
      MusumeView(index: scoreInfo.offset, width: 40, height: 55)
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(subject.rating.score.rateDisplay)
            .font(.system(size: 30, weight: .heavy, design: .monospaced))
            .foregroundStyle(theme.accentDeep)
          if subject.rating.score > 0 {
            Text(scoreInfo.desc)
              .font(.subheadline.weight(.bold))
              .foregroundStyle(theme.cardTitle)
          }
          Spacer(minLength: 0)
          Text("\(subject.rating.total) 人评分")
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(theme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(theme.controlFill, in: Capsule())
            .overlay {
              Capsule().strokeBorder(theme.controlBorder, lineWidth: 1)
            }
        }
        if subject.rating.rank > 0 {
          HStack(spacing: 4) {
            Text("Bangumi \(subject.type.name.capitalized) Ranked")
              .foregroundStyle(theme.tertiaryText)
            Text("#\(subject.rating.rank)")
              .monospacedDigit()
              .foregroundStyle(theme.rank)
          }
          .font(.caption)
        }
      }
    }
  }
}
