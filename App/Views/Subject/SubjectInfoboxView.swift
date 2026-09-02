import OSLog
import SwiftUI

let WIKI_PINS: [String] = ["中文名", "册数", "话数", "放送开始", "放送星期"]
let WIKI_NEWLINES: Set<String> = [
  "别名"
]
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
let WIKI_LINK_ORDER: [String] = [
  "链接", "相关链接", "官网", "官方网站", "website",
  "引用来源", "HP", "个人博客", "博客", "Blog", "主页",
]
let WIKI_LINK_SET: Set<String> = Set(WIKI_LINK_ORDER)

struct SubjectInfoboxView: View {
  let subjectId: Int

  @State private var loaded: Bool = false
  @State private var subject: SubjectDTO?
  @State private var detail: SubjectDetailDTO = SubjectDetailDTO()

  private func loadCached(animated: Bool = false) async {
    do {
      let db = try await AppContext.shared.getDB()
      let cachedSubject = try await db.getSubjectDTO(subjectId)
      let cachedDetail = try await db.getSubjectDetailDTO(subjectId)
      if animated {
        withAnimation(.default) {
          subject = cachedSubject
          detail = cachedDetail
        }
      } else {
        subject = cachedSubject
        detail = cachedDetail
      }
    } catch {
      Logger.app.error("Failed to load cached subject infobox: \(error)")
    }
  }

  func load() async {
    if loaded { return }
    loaded = true
    await loadCached()
    if !detail.positions.isEmpty {
      return
    }
    await refresh()
  }

  func refresh() async {
    do {
      try await SubjectRepository.loadSubjectPositions(subjectId)
      await loadCached(animated: true)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      if let subject = subject {
        SubjectInfoboxDetailView(subject: subject, positions: detail.positions)
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
  }
}

struct SubjectInfoboxDetailView: View {
  let subject: SubjectDTO
  let positions: [SubjectPositionDTO]

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @State private var showVersion: [String: Bool] = [:]
  @State private var showFolded: Bool = false

  private struct StaffEntry: Hashable {
    let id: Int
    let display: String
    let names: [String]
  }

  private func displayPositionTitle(_ position: SubjectStaffPositionType) -> String {
    if !position.cn.isEmpty {
      return position.cn
    }
    if !position.jp.isEmpty {
      return position.jp
    }
    if !position.en.isEmpty {
      return position.en
    }
    return "Staff"
  }

  private func positionLabels(_ position: SubjectStaffPositionType) -> [String] {
    var labels: [String] = []
    if !position.cn.isEmpty {
      labels.append(position.cn)
    }
    if !position.jp.isEmpty {
      labels.append(position.jp)
    }
    if !position.en.isEmpty {
      labels.append(position.en)
    }
    if labels.isEmpty {
      labels.append("Staff")
    }
    return labels
  }

  private func positionKey(
    for position: SubjectStaffPositionType,
    infoboxKeys: Set<String>
  ) -> String {
    let labels = positionLabels(position)
    if let matched = labels.first(where: { infoboxKeys.contains($0) }) {
      return matched
    }
    return displayPositionTitle(position)
  }

  private func staffEntries(_ staffValues: [SubjectPositionStaffDTO]) -> [StaffEntry] {
    staffValues.map { staff in
      let display = staff.person.title(with: titlePreference)
      var names: [String] = []
      if !staff.person.name.isEmpty {
        names.append(staff.person.name)
      }
      if !staff.person.nameCN.isEmpty {
        names.append(staff.person.nameCN)
      }
      if !display.isEmpty && !names.contains(display) {
        names.append(display)
      }
      return StaffEntry(id: staff.person.id, display: display, names: names)
    }
  }

  private func mergeValues(
    _ wikiValues: [InfoboxValue],
    staffValues: [SubjectPositionStaffDTO]
  ) -> [InfoboxValue] {
    guard !staffValues.isEmpty else { return wikiValues }
    let entries = staffEntries(staffValues)
    var appeared = Set<Int>()
    for value in wikiValues {
      for entry in entries {
        if entry.names.contains(where: { !($0.isEmpty) && value.v.contains($0) }) {
          appeared.insert(entry.id)
        }
      }
    }
    let missing = entries.filter { !appeared.contains($0.id) }.map { $0.display }.filter {
      !$0.isEmpty
    }
    let keyedValues = wikiValues.filter { $0.k != nil }
    let noKeyValues = wikiValues.filter { $0.k == nil }.map { $0.v }.filter { !$0.isEmpty }
    var base = noKeyValues.joined(separator: "、")
    if !missing.isEmpty {
      if !base.isEmpty {
        base += "、"
      }
      base += missing.joined(separator: "、")
    }
    if keyedValues.isEmpty {
      if base.isEmpty {
        return wikiValues
      }
      return [InfoboxValue(k: nil, v: base)]
    }
    var result: [InfoboxValue] = []
    if !base.isEmpty {
      result.append(InfoboxValue(k: nil, v: base))
    }
    result.append(contentsOf: keyedValues)
    return result
  }

  var orderedKeys: [String] {
    var ordered: [String] = []
    let infoboxKeys = subject.infobox.map { $0.key }
    let infoboxKeySet = Set(infoboxKeys)
    var seen = Set<String>()
    for position in positions {
      let key = positionKey(for: position.position, infoboxKeys: infoboxKeySet)
      if key.isEmpty || seen.contains(key) {
        continue
      }
      seen.insert(key)
      ordered.append(key)
    }
    for key in infoboxKeys where !seen.contains(key) {
      seen.insert(key)
      ordered.append(key)
    }
    for key in WIKI_LINK_ORDER {
      if let index = ordered.firstIndex(of: key) {
        ordered.remove(at: index)
        ordered.append(key)
      }
    }
    return ordered
  }

  var fields: [String] {
    var ordered = orderedKeys
    ordered.removeAll { WIKI_PINS.contains($0) }
    ordered.removeAll { WIKI_NEWLINES.contains($0) }
    ordered.removeAll { WIKI_FOLDED.contains($0) }
    return ordered
  }

  var infobox: [String: [InfoboxValue]] {
    var infobox: [String: [InfoboxValue]] = [:]
    for item in subject.infobox {
      infobox[item.key] = item.values
    }
    return infobox
  }

  var positionsByKey: [String: [SubjectPositionStaffDTO]] {
    var grouped: [String: [SubjectPositionStaffDTO]] = [:]
    let infoboxKeySet = Set(subject.infobox.map { $0.key })
    for position in positions {
      let key = positionKey(for: position.position, infoboxKeys: infoboxKeySet)
      grouped[key, default: []].append(contentsOf: position.staffs)
    }
    return grouped
  }

  var mergedInfobox: [String: [InfoboxValue]] {
    var merged = infobox
    let infoboxKeySet = Set(subject.infobox.map { $0.key })
    for position in positions {
      let key = positionKey(for: position.position, infoboxKeys: infoboxKeySet)
      let wikiValues = merged[key] ?? []
      merged[key] = mergeValues(wikiValues, staffValues: position.staffs)
    }
    return merged
  }

  func fieldContent(key: String) -> AttributedString {
    let infoboxValues = mergedInfobox[key] ?? []
    let positionValues = positionsByKey[key] ?? []
    var persons: [String: SlimPersonDTO] = [:]
    for staff in positionValues {
      persons[staff.person.name] = staff.person
      if !staff.person.nameCN.isEmpty {
        persons[staff.person.nameCN] = staff.person
      }
      let display = staff.person.title(with: titlePreference)
      if !display.isEmpty {
        persons[display] = staff.person
      }
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
          for position in positionsByKey[k] ?? [] {
            vps[position.person.name] = position.person
            if !position.person.nameCN.isEmpty {
              vps[position.person.nameCN] = position.person
            }
            let display = position.person.title(with: titlePreference)
            if !display.isEmpty {
              vps[display] = position.person
            }
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

  var newlineItems: [String: [AttributedString]] {
    var items: [String: [AttributedString]] = [:]
    for field in WIKI_NEWLINES {
      let values = infobox[field] ?? []
      if values.isEmpty {
        continue
      }
      var vals: [AttributedString] = []
      for value in values {
        var text = AttributedString("")
        if let k = value.k, !k.isEmpty {
          var ks = AttributedString("\(k): ")
          ks.foregroundColor = .secondary
          text += ks
        }
        text += AttributedString(value.v)
        vals.append(text)
      }
      items[field] = vals
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
    for field in orderedKeys where WIKI_FOLDED.contains(field) {
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
    VStack(alignment: .leading) {
      ForEach(pinnedItems, id: \.self) { item in
        Text(item)
          .tint(.linkText)
          .textSelection(.enabled)
        Divider()
      }
      ForEach(Array(newlineItems.keys.sorted()), id: \.self) { key in
        HStack(alignment: .top) {
          Text("\(key): ").bold()
          VStack(alignment: .leading, spacing: 5) {
            ForEach(newlineItems[key] ?? [], id: \.self) { item in
              Text(item).textSelection(.enabled)
              if item != newlineItems[key]?.last {
                Divider()
              }
            }
          }
          Spacer(minLength: 0)
        }
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
          withAnimation(.default) {
            if showVersion[key] == nil {
              showVersion[key] = true
            } else {
              showVersion[key]?.toggle()
            }
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
      if !foldedItems.isEmpty {
        if showFolded {
          ForEach(foldedItems, id: \.self) { item in
            Text(item)
              .tint(.linkText)
              .textSelection(.enabled)
            Divider()
          }
        } else {
          Button {
            withAnimation(.default) {
              showFolded.toggle()
            }
          } label: {
            HStack {
              Spacer()
              Label("更多制作人员", systemImage: "plus")
              Spacer()
            }
          }.buttonStyle(.navigation)
        }
      }
    }
    .padding(8)
  }
}
