import SwiftData
import SwiftUI

let WIKI_PINS: [String] = ["中文名", "册数", "话数", "放送开始", "放送星期"]
let WIKI_FOLDED: [String] = [
  "主动画师",
  "作画监督助理",
  "原画",
  "补间动画",
  "第二原画",
  "背景美术",
  "助理制片人",
  "色彩指定",
  "颜色检查",
  "动画检查",
  "上色",
  "宣传",
  "制作协力",
  "制作进行协力",
  "制作助理",
  "茶水",
  "摄影",
  "音乐助理",
  "其他电视台",
  "顾问",
  "仕上",
]
// let WIKI_TAG_SET: Set<String> = ["平台", "其他电视台"]
let WIKI_LINK_SET: Set<String> = [
  "链接", "相关链接", "官网", "官方网站", "website",
  "引用来源", "HP", "个人博客", "博客", "Blog", "主页",
]

struct SubjectInfoboxView: View {
  let subjectId: Int

  @Query private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  @State private var loaded: Bool = false

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
  }

  func load() async {
    if loaded { return }
    loaded = true
    guard let subject = subject else { return }
    if !subject.positions.isEmpty {
      return
    }
    await refresh()
  }

  func refresh() async {
    do {
      try await Chii.shared.loadSubjectPositions(subjectId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      if let subject = subject {
        SubjectInfoboxDetailView()
          .environment(subject)
      }
    }
    .task {
      await load()
    }
    .refreshable {
      await refresh()
    }
    .navigationTitle("条目信息")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "info.circle").foregroundStyle(.secondary)
      }
    }
  }
}

struct SubjectInfoboxDetailView: View {
  @Environment(Subject.self) private var subject

  @State private var showVersion: [String: Bool] = [:]
  @State private var showFolded: Bool = false

  var fields: [String] {
    var fields: [String] = []
    let infoboxKeys = subject.infobox.map { $0.key }
    fields.append(contentsOf: infoboxKeys)
    let positionKeys = subject.positions.map { $0.position.cn }.filter { !$0.isEmpty }.filter {
      !infoboxKeys.contains($0)
    }
    fields.append(contentsOf: positionKeys)
    fields.removeAll { WIKI_PINS.contains($0) }
    fields.removeAll { WIKI_FOLDED.contains($0) }
    return fields
  }

  var infobox: [String: [InfoboxValue]] {
    var infobox: [String: [InfoboxValue]] = [:]
    for item in subject.infobox {
      infobox[item.key] = item.values
    }
    return infobox
  }

  var positions: [String: [SubjectPositionStaffDTO]] {
    var positions: [String: [SubjectPositionStaffDTO]] = [:]
    for position in subject.positions {
      if position.position.cn.isEmpty {
        continue
      }
      positions[position.position.cn] = position.staffs
    }
    return positions
  }

  func fieldContent(key: String) -> AttributedString {
    let infoboxValues = infobox[key] ?? []
    let positionValues = positions[key] ?? []
    let persons: [String: SlimPersonDTO] = positionValues.reduce(into: [String: SlimPersonDTO]()) {
      $0[$1.person.name] = $1.person
    }
    var lines: [AttributedString] = []
    if WIKI_LINK_SET.contains(key) {
      for value in infoboxValues {
        if let k = value.k {
          var text = AttributedString(k)
          text.link = URL(string: value.v)
          text.strokeWidth = 1
          text.strokeColor = .gray
          lines.append(text)
        } else {
          var text = AttributedString(value.v)
          text.link = URL(string: value.v)
          lines.append(text)
        }
      }
    } else {
      for value in infoboxValues {
        var text = AttributedString("")
        var vps: [String: SlimPersonDTO] = [:]
        if let k = value.k, !k.isEmpty {
          var ks = AttributedString("\(k): ")
          ks.foregroundColor = .secondary
          text += ks
          for position in positions[k] ?? [] {
            vps[position.person.name] = position.person
          }
        }
        var val = AttributedString(value.v)
        for (name, person) in persons {
          if let range = val.range(of: name) {
            val[range].link = URL(string: person.link)
          }
        }
        for (name, person) in vps {
          if let range = val.range(of: name) {
            val[range].link = URL(string: person.link)
          }
        }
        lines.append(text + val)
      }
    }
    var result = AttributedString("")
    for line in lines {
      if !result.characters.isEmpty {
        result += AttributedString("\n")
      }
      result += line
    }
    return result
  }

  var pinnedItems: [AttributedString] {
    var items: [AttributedString] = []
    for field in WIKI_PINS {
      let content = fieldContent(key: field)
      if !content.characters.isEmpty {
        var text = AttributedString("\(field): ")
        text.font = .body.bold()
        text += content
        items.append(text)
      }
    }
    return items
  }

  var items: [AttributedString] {
    var items: [AttributedString] = []
    for field in fields {
      if field.starts(with: "版本:") {
        continue
      }
      let content = fieldContent(key: field)
      if !content.characters.isEmpty {
        var text = AttributedString("\(field): ")
        text.font = .body.bold()
        text += content
        items.append(text)
      }
    }
    return items
  }

  var versionItems: [String: AttributedString] {
    var items: [String: AttributedString] = [:]
    for field in fields {
      if !field.starts(with: "版本:") {
        continue
      }
      let key = field.replacingOccurrences(of: "版本:", with: "")
      let content = fieldContent(key: field)
      items[key] = content
    }
    return items
  }

  var foldedItems: [AttributedString] {
    var items: [AttributedString] = []
    for field in WIKI_FOLDED {
      let content = fieldContent(key: field)
      if !content.characters.isEmpty {
        var text = AttributedString("\(field): ")
        text.font = .body.bold()
        text += content
        items.append(text)
      }
    }
    return items
  }

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(pinnedItems, id: \.self) { item in
        Text(item)
          .tint(.linkText)
          .textSelection(.enabled)
        Divider()
      }
      ForEach(items, id: \.self) { item in
        Text(item)
          .tint(.linkText)
          .textSelection(.enabled)
        Divider()
      }
      ForEach(Array(versionItems.keys.sorted()), id: \.self) { key in
        Button {
          if showVersion[key] == nil {
            showVersion[key] = true
          } else {
            showVersion[key]?.toggle()
          }
        } label: {
          Text(key + " " + (showVersion[key] ?? false ? "▼" : "▶"))
            .font(.headline)
        }.buttonStyle(.navigation)
        Divider()
        if showVersion[key] ?? false {
          Text(versionItems[key] ?? AttributedString(""))
            .tint(.linkText)
            .textSelection(.enabled)
          Divider()
        }
      }
      if showFolded {
        ForEach(foldedItems, id: \.self) { item in
          Text(item)
            .tint(.linkText)
            .textSelection(.enabled)
          Divider()
        }
      } else {
        Button {
          showFolded.toggle()
        } label: {
          HStack {
            Spacer()
            Label("更多制作人员", systemImage: "plus")
            Spacer()
          }
        }.buttonStyle(.navigation)
      }
    }
    .animation(.default, value: subject.positions)
    .animation(.default, value: showFolded)
    .animation(.default, value: showVersion)
    .padding(8)
  }
}
