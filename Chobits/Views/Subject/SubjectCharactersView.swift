import SwiftData
import SwiftUI

struct SubjectCharactersView: View {
  let subjectId: Int
  let characters: [SubjectCharacterDTO]

  @AppStorage("isolationMode") var isolationMode: Bool = false

  var rowCount: Int {
    let count = characters.count / 3
    if count > 3 {
      return 3
    }
    return count
  }

  var rows: [GridItem] {
    return Array(repeating: GridItem(.fixed(60)), count: rowCount)
  }

  var height: CGFloat {
    let height = CGFloat(rowCount) * 64
    if height > 0 {
      return height
    }
    return 2
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("角色介绍")
          .foregroundStyle(characters.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if characters.count > 0 {
          NavigationLink(value: NavDestination.subjectCharacterList(subjectId)) {
            Text("更多角色 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
    }.padding(.top, 5)
    Divider()
    if characters.count == 0 {
      HStack {
        Spacer()
        Text("暂无角色")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(5)
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHGrid(rows: rows, alignment: .top) {
        ForEach(characters, id: \.character.id) { item in
          HStack(alignment: .top) {
            NavigationLink(value: NavDestination.character(item.character.id)) {
              ImageView(img: item.character.images?.grid)
                .imageStyle(width: 60, height: 60, alignment: .top)
                .imageType(.person)
                .padding(2)
                .shadow(radius: 2)
            }.buttonStyle(.navLink)
            VStack(alignment: .leading, spacing: 2) {
              HStack {
                NavigationLink(value: NavDestination.character(item.character.id)) {
                  Text(item.character.name)
                    .font(.footnote)
                    .lineLimit(1)
                }.buttonStyle(.navLink)
                Spacer()
                if let comment = item.character.comment, comment > 0, !isolationMode {
                  Text("(+\(comment))")
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.orange)
                }
              }
              Divider()
              HStack {
                BorderView(padding: 2) {
                  Text(item.type.description)
                }
                if !item.character.nameCN.isEmpty {
                  Text(item.character.nameCN)
                    .lineLimit(1)
                }
                Spacer()
              }
              .font(.caption)
              .foregroundStyle(.secondary)
              if let actor = item.actors.first {
                HStack {
                  Text("CV:").foregroundStyle(.secondary)
                  NavigationLink(value: NavDestination.person(actor.id)) {
                    Text(actor.name)
                      .lineLimit(1)
                  }.buttonStyle(.navLink)
                }.font(.caption)
              }
              Spacer()
            }
          }.frame(width: 180)
        }
      }.frame(height: height)
    }.animation(.default, value: characters)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectCharactersView(
          subjectId: Subject.previewAnime.subjectId,
          characters: Subject.previewCharacters)
      }.padding()
    }
  }
}
