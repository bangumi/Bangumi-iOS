import Flow
import SwiftData
import SwiftUI

struct PersonWorkListView: View {
  let personId: Int

  @State private var subjectType: SubjectType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<PersonWorkDTO>? {
    do {
      let resp = try await Chii.shared.getPersonWorks(
        personId, subjectType: subjectType, limit: limit, offset: offset)
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
      PageView<PersonWorkDTO, _>(limit: 10, reloader: reloader, nextPageFunc: load) { item in
        CardView {
          HStack(alignment: .top) {
            ImageView(img: item.subject.images?.resize(.r200))
              .imageStyle(width: 60, height: 60)
              .imageType(.subject)
              .imageLink(item.subject.link)
            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                Text(item.subject.name.withLink(item.subject.link))
                  .font(.callout)
                  .lineLimit(1)
                if item.subject.nameCN.isEmpty {
                  Label(item.subject.type.description, systemImage: item.subject.type.icon)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } else {
                  Label(item.subject.nameCN, systemImage: item.subject.type.icon)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Text(item.subject.info)
                  .font(.caption)
                  .lineLimit(1)
                  .foregroundStyle(.secondary)
                Divider()
              }.frame(height: 60)
              HFlow {
                ForEach(item.positions) { position in
                  HStack {
                    BorderView {
                      Text(position.type.cn).font(.caption)
                    }
                  }
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                }
              }
            }
            Spacer()
          }
        }
      }
      .padding(8)
    }
    .buttonStyle(.navLink)
    .navigationTitle("参与作品")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let person = Person.preview
  return PersonWorkListView(personId: person.personId)
}
