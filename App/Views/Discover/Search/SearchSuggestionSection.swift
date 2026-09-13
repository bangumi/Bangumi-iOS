import OSLog
import SwiftUI

struct SearchSuggestionSection: View {
  let subjectType: SubjectType
  let reloadToken: Int
  var onSelect: (String) -> Void

  private static let limit = 12

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @State private var keywords: [String] = []

  private func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      var items: [TrendingSubjectDTO] = []
      if subjectType == .none {
        for type in SubjectType.allTypes {
          items.append(contentsOf: try await db.fetchTrendingSubjects(type: type))
        }
        items.sort { $0.count > $1.count }
      } else {
        items = try await db.fetchTrendingSubjects(type: subjectType)
      }
      var seen: Set<String> = []
      var result: [String] = []
      for item in items {
        let title = item.subject.title(with: titlePreference)
          .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, seen.insert(title).inserted else { continue }
        result.append(title)
        if result.count >= Self.limit { break }
      }
      keywords = result
    } catch {
      Logger.app.warning("load search suggestions failed: \(error)")
    }
  }

  var body: some View {
    Group {
      if !keywords.isEmpty {
        VStack(alignment: .leading, spacing: 10) {
          ThemedSectionHeader("建议搜索", systemImage: "sparkle.magnifyingglass")
          LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80), spacing: 8)],
            alignment: .leading,
            spacing: 8
          ) {
            ForEach(keywords, id: \.self) { keyword in
              Button {
                onSelect(keyword)
              } label: {
                Text(keyword)
                  .lineLimit(1)
              }
              .buttonStyle(.themedChip(isSelected: false))
            }
          }
        }
      }
    }
    .task(id: "\(subjectType.rawValue)-\(reloadToken)") {
      await load()
    }
  }
}
