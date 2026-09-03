import SwiftUI

struct BarItem: Identifiable {
  var name: String
  var value: UInt
  var height: CGFloat
  var percent: String

  var id: String { name }

  init(name: String, value: UInt) {
    self.name = name
    self.value = value
    self.height = 0
    self.percent = ""
  }

  init(name: String, value: UInt, height: CGFloat, percent: String) {
    self.name = name
    self.value = value
    self.height = height
    self.percent = percent
  }
}

struct ChartView: View {
  let title: String
  let data: [String: UInt]
  let width: CGFloat
  let height: CGFloat

  @State private var tappedItem: BarItem? = nil

  @Environment(\.theme) private var theme

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

  var dataTotal: UInt {
    data.values.reduce(0, +)
  }

  var barSpacing: CGFloat {
    if data.count == 0 {
      return 0
    }
    return (width / CGFloat(data.count)) * 0.15
  }

  func buildBarItem(name: String, value: UInt) -> BarItem {
    if let maxValue = data.values.max() {
      if maxValue == 0 {
        return BarItem(name: name, value: value)
      }
      let percent = String(format: "%.1f%%", 100 * CGFloat(value) / CGFloat(dataTotal))
      let barHeight = (height - 64) * CGFloat(value) / CGFloat(maxValue)
      return BarItem(name: name, value: value, height: barHeight, percent: percent)
    }
    return BarItem(name: name, value: value)
  }

  var barList: [BarItem] {
    let sorted = data.sorted { first, second -> Bool in
      first.key.localizedStandardCompare(second.key) == .orderedDescending
    }
    return sorted.map {
      buildBarItem(name: $0.key, value: $0.value)
    }
  }

  @ViewBuilder
  func bar(_ item: BarItem) -> some View {
    if theme.isClassic {
      Rectangle()
        .fill(.secondary)
    } else {
      Rectangle()
        .fill(glassBarStyle(item))
    }
  }

  func glassBarStyle(_ item: BarItem) -> AnyShapeStyle {
    if let maxValue = data.values.max(), maxValue > 0, item.value == maxValue {
      return AnyShapeStyle(
        LinearGradient(colors: theme.ctaGradient, startPoint: .bottom, endPoint: .top))
    }
    return AnyShapeStyle(theme.accent.opacity(barOpacity(item)))
  }

  func barOpacity(_ item: BarItem) -> Double {
    guard let maxValue = data.values.max(), maxValue > 0 else {
      return 0.35
    }
    return 0.35 + 0.45 * Double(item.value) / Double(maxValue)
  }

  func trackColor(tapped: Bool) -> Color {
    if theme.isClassic {
      return tapped ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.01)
    }
    return tapped ? theme.tint : theme.accent.opacity(0.01)
  }

  var body: some View {
    VStack {
      Spacer()
      if let item = tappedItem {
        Text("\(item.percent)(\(item.value))")
      } else {
        Text(title)
      }
      if show {
        HStack(alignment: .bottom, spacing: barSpacing) {
          ForEach(barList, id: \.name) { item in
            VStack {
              Spacer()
              ZStack {
                VStack {
                  Spacer()
                  bar(item)
                    .frame(width: barWidth, height: item.height)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                Rectangle()
                  .fill(trackColor(tapped: tappedItem?.name == item.name))
                  .frame(width: barWidth, height: height - 60)
                  .clipShape(RoundedRectangle(cornerRadius: 2))
              }
              Text(item.name).font(.footnote)
            }
            .onTapGesture {
              if tappedItem?.name == item.name {
                tappedItem = nil
              } else {
                tappedItem = item
              }
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
}
