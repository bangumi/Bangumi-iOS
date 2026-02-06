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
                let sortedCasts = item.casts.sorted {
                  if $0.relation != $1.relation {
                    return $0.relation.rawValue < $1.relation.rawValue
                  }
                  return $0.person.id < $1.person.id
                }
                ForEach(sortedCasts) { cast in
                  HStack(alignment: .top) {
                    ImageView(img: cast.person.images?.grid)
                      .imageStyle(width: 40, height: 40, alignment: .top)
                      .imageType(.person)
                      .imageNavLink(cast.person.link)
                    VStack(alignment: .leading, spacing: 2) {
                      Text(cast.person.title(with: titlePreference).withLink(cast.person.link))
                        .foregroundStyle(.linkText)
                        .font(.footnote)
                        .lineLimit(1)
                      HStack(spacing: 4) {
                        BorderView {
                          Text(cast.relation.description).font(.caption)
                        }
                        if !cast.summary.isEmpty {
                          Text(cast.summary)
                            .font(.caption)
                            .lineLimit(1)
                        }
                      }
                      .foregroundStyle(.secondary)
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
