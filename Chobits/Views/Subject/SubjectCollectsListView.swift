import SwiftData
import SwiftUI

struct SubjectCollectsListView: View {
  let subjectId: Int

  @State private var reloader = false
  @State private var selectedType: CollectionType
  @State private var selectedMode: FilterMode = .all

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    self._selectedType = State(initialValue: .collect)
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  var title: String {
    switch selectedMode {
    case .all:
      return "收藏用户"
    case .friends:
      return "好友收藏"
    }
  }

  var subjectType: SubjectType {
    subject?.typeEnum ?? .none
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectCollectDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectCollects(
        subjectId,
        type: selectedType,
        mode: selectedMode,
        limit: limit,
        offset: offset
      )
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      VStack {
        Picker("Type", selection: $selectedType) {
          ForEach(CollectionType.allTypes(), id: \.self) { ct in
            Text(ct.description(subjectType))
              .tag(ct)
          }
        }.pickerStyle(.segmented)
        Picker("Mode", selection: $selectedMode) {
          ForEach(FilterMode.allCases, id: \.self) { mode in
            Text(mode.description)
              .tag(mode)
          }
        }.pickerStyle(.segmented)
      }
      .padding(.horizontal, 8)
      .onChange(of: selectedType) { _, _ in
        reloader.toggle()
      }
      .onChange(of: selectedMode) { _, _ in
        reloader.toggle()
      }

      ScrollView {
        PageView<SubjectCollectDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load) {
          item in
          SubjectCollectRowView(collect: item, subjectType: subjectType)
          Divider()
        }.padding(8)
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct SubjectCollectRowView: View {
  let collect: SubjectCollectDTO
  let subjectType: SubjectType

  var typeText: String {
    collect.interest.type.description(subjectType)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ImageView(img: collect.user.avatar?.large)
        .imageStyle(width: 60, height: 60)
        .imageType(.avatar)
        .imageLink(collect.user.link)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(collect.user.nickname)
            .font(.headline)

          Spacer()

          Label(typeText, systemImage: collect.interest.type.icon)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        HStack {
          StarsView(score: Float(collect.interest.rate), size: 12)
          Spacer()
          collect.interest.updatedAt.relativeText
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }

        if !collect.interest.tags.isEmpty {
          Text("标签: \(collect.interest.tags.joined(separator: ", "))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if !collect.interest.comment.isEmpty {
          Divider()
          Text(collect.interest.comment)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }

      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    SubjectCollectsListView(subjectId: 8)
  }
}
