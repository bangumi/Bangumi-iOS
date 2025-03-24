import SwiftData
import SwiftUI

struct SubjectCharactersView: View {
  let subjectId: Int
  let characters: [SubjectCharacterDTO]

  @AppStorage("isolationMode") var isolationMode: Bool = false

  var rowCount: Int {
    if characters.count == 0 {
      return 0
    }
    let count = characters.count / 3
    return max(1, min(count, 3))
  }

  var rows: [GridItem] {
    return Array(repeating: GridItem(.fixed(60)), count: rowCount)
  }

  var height: CGFloat {
    let height = CGFloat(rowCount) * 68
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
          }.buttonStyle(.navigation)
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
            ImageView(img: item.character.images?.grid)
              .imageStyle(width: 60, height: 60, alignment: .top)
              .imageType(.person)
              .imageLink(item.character.link)
              .padding(2)
              .shadow(radius: 2)
            VStack(alignment: .leading, spacing: 2) {
              HStack {
                Text(item.character.name.withLink(item.character.link))
                  .font(.callout)
                  .lineLimit(1)
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
                    .font(.caption)
                }
                if !item.character.nameCN.isEmpty {
                  Text(item.character.nameCN)
                    .font(.footnote)
                    .lineLimit(1)
                }
                Spacer()
              }.foregroundStyle(.secondary)
              if let actor = item.actors.first {
                HStack {
                  Text("CV:").foregroundStyle(.secondary)
                  Text(actor.name.withLink(actor.link))
                    .lineLimit(1)
                }.font(.caption)
              }
              Spacer()
            }
          }.frame(width: 220)
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
