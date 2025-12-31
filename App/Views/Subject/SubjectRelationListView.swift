import SwiftData
import SwiftUI

struct SubjectRelationListView: View {
  let subjectId: Int

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectRelationDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectRelations(
        subjectId, type: subjectType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Subject Type", selection: $subjectType) {
      ForEach(SubjectType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: subjectType) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<SubjectRelationDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        CardView {
          HStack {
            ImageView(img: item.subject.images?.resize(.r200))
              .imageStyle(width: 60, height: 60)
              .imageType(.subject)
              .imageNavLink(item.subject.link)
            VStack(alignment: .leading) {
              HStack {
                VStack(alignment: .leading) {
                  Text(item.subject.title(with: titlePreference).withLink(item.subject.link))
                    .lineLimit(1)
                  if let subtitle = item.subject.subtitle(with: titlePreference) {
                    Text(subtitle)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                  Label(item.relation.cn, systemImage: item.subject.type.icon)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Spacer()
              }
            }.padding(.leading, 4)
          }
        }
      }.padding(8)
    }
    .navigationTitle("关联条目")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return SubjectRelationListView(subjectId: subject.subjectId)
    .modelContainer(container)
}
