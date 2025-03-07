import SwiftUI

struct GroupListView: View {
  let mode: GroupFilterMode

  @State private var sortMode: GroupSortMode = .members
  @State private var reloader = false

  private func load(limit: Int, offset: Int) async -> PagedDTO<SlimGroupDTO>? {
    do {
      let resp = try await Chii.shared.getGroups(
        mode: mode,
        sort: sortMode,
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
    ScrollView {
      PageView(reloader: reloader, nextPageFunc: load) { (group: SlimGroupDTO) in
        CardView {
          HStack {
            ImageView(img: group.icon?.large)
              .imageStyle(width: 60, height: 60)
              .imageType(.icon)
              .imageLink(group.link)
            VStack(alignment: .leading, spacing: 8) {
              Text(group.title.withLink(group.link))
                .font(.headline)
              if let createdAt = group.createdAt {
                Text("创建时间: \(createdAt.datetimeDisplay)")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
              if let members = group.members {
                Label("\(members) 位成员", systemImage: "person.2")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
            Spacer()
          }
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle(mode.description)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          ForEach(GroupSortMode.allCases, id: \.self) { mode in
            Button {
              sortMode = mode
              reloader.toggle()
            } label: {
              if sortMode == mode {
                Label(mode.description, systemImage: "checkmark")
              } else {
                Text(mode.description)
              }
            }
          }
        } label: {
          Image(systemName: "arrow.up.arrow.down")
        }
      }
    }
  }
}
