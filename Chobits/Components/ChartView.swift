//
//  ChartView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/11.
//

import SwiftUI

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
              .clipShape(RoundedRectangle(cornerRadius: 2))
            Text(key)
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
  let subject = Subject.previewAnime
  return VStack {
    ChartView(data: subject.rating.count, width: 360, height: 200)
  }
}
