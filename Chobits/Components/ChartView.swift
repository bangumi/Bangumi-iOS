//
//  ChartView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/11.
//

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
                  Rectangle()
                    .fill(.secondary)
                    .frame(width: barWidth, height: item.height)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                Rectangle()
                  .fill(
                    tappedItem?.name == item.name
                      ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.01)
                  )
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

#Preview {
  let subject = Subject.previewAnime
  return VStack {
    ChartView(
      title: "数据统计", data: subject.rating.count,
      width: 360, height: 240
    )
    .frame(width: 360, height: 240)
    .clipped()
  }
}
