import Flow
import SwiftData
import SwiftUI

struct SubjectCharacterListView: View {
  let subjectId: Int

  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var castType: CastType = .none
  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectCharacterDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectCharacters(
        subjectId, type: castType, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    Picker("Cast Type", selection: $castType) {
      ForEach(CastType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onChange(of: castType) { _, _ in
      reloader.toggle()
    }
    ScrollView {
      PageView<SubjectCharacterDTO, _>(limit: 10, reloader: reloader, nextPageFunc: load) { item in
        CardView {
          HStack {
            ImageView(img: item.character.images?.medium)
              .imageStyle(width: 60, height: 90, alignment: .top)
              .imageType(.person)
              .imageCaption {
                Text(item.type.description)
              }
              .imageNavLink(item.character.link)
            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                HStack {
                  Text(item.character.title(with: titlePreference).withLink(item.character.link))
                    .foregroundStyle(.linkText)
                    .lineLimit(1)
                  Spacer()
                  if let comment = item.character.comment, comment > 0, !isolationMode {
                    Text("(+\(comment))")
                      .font(.caption)
                      .foregroundStyle(.orange)
                  }
                }
                if let subtitle = item.character.subtitle(with: titlePreference) {
                  Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
              }
              HFlow {
                ForEach(item.actors) { person in
                  HStack {
                    ImageView(img: person.images?.grid)
                      .imageStyle(width: 40, height: 40, alignment: .top)
                      .imageType(.person)
                      .imageNavLink(person.link)
                    VStack(alignment: .leading) {
                      Text(person.title(with: titlePreference).withLink(person.link))
                        .foregroundStyle(.linkText)
                        .font(.footnote)
                        .lineLimit(1)
                      if let subtitle = person.subtitle(with: titlePreference) {
                        Text(subtitle)
                          .font(.footnote)
                          .foregroundStyle(.secondary)
                          .lineLimit(1)
                      }
                    }
                  }
                }
              }
            }.padding(.leading, 4)
          }
        }
      }.padding(8)
    }
    .buttonStyle(.scale)
    .navigationTitle("角色列表")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let subject = Subject.previewAnime
  return SubjectCharacterListView(subjectId: subject.subjectId)
}
