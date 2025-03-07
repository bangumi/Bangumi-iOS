import SwiftData
import SwiftUI

struct EpisodeRowView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Episode.self) var episode

  var body: some View {
    VStack(alignment: .leading) {
      Text(episode.titleLink)
        .font(.headline)
        .lineLimit(1)
      HStack {
        if isAuthenticated && episode.collectionTypeEnum != .none {
          BorderView(color: episode.borderColor, padding: 4) {
            Text("\(episode.collectionTypeEnum.description)")
              .foregroundStyle(episode.textColor)
              .font(.footnote)
          }
          .padding(2)
          .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
          .background {
            RoundedRectangle(cornerRadius: 5)
              .fill(episode.backgroundColor)
          }
        } else {
          Menu {
            EpisodeUpdateMenu().environment(episode)
          } label: {
            if episode.typeEnum == .main {
              if episode.aired {
                BorderView(color: .primary, padding: 4) {
                  Text("已播")
                    .foregroundStyle(.primary)
                    .font(.footnote)
                }
              } else {
                BorderView(padding: 4) {
                  Text("未播")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
              }
            } else {
              BorderView(color: .primary, padding: 4) {
                Text(episode.typeEnum.description)
                  .foregroundStyle(.primary)
                  .font(.footnote)
              }
            }
          }.buttonStyle(.scale)
        }
        VStack(alignment: .leading) {
          HStack {
            Label("\(episode.duration)", systemImage: "clock")
            Label("\(episode.airdate)", systemImage: "calendar")
            Spacer()
            if !isolationMode {
              Label("+\(episode.comment)", systemImage: "bubble")
            }
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
          Divider()
        }
        Spacer()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  let episodes = Episode.previewAnime
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack {
      EpisodeRowView().environment(episodes.first!)
        .modelContainer(container)
    }.padding()
  }
}
