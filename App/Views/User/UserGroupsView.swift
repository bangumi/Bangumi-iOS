import SwiftUI

struct UserGroupsView: View {
  @Bindable var user: User

  @State private var refreshing = false
  @State private var groups: [SlimGroupDTO] = []

  func refresh() async {
    if refreshing { return }
    refreshing = true
    do {
      let resp = try await Chii.shared.getUserGroups(
        username: user.username, limit: 20)
      groups = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .bottom) {
        NavigationLink(value: NavDestination.userGroup(user.slim)) {
          Text("小组").font(.title3)
        }
        .buttonStyle(.navigation)
        .padding(.horizontal, 4)

        Spacer(minLength: 0)
      }
      .padding(.top, 8)
      .task {
        if !groups.isEmpty {
          return
        }
        await refresh()
      }
      Divider()

      if refreshing {
        HStack {
          Spacer()
          ProgressView().padding()
          Spacer()
        }
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHGrid(rows: [GridItem(.flexible()), GridItem(.flexible())], alignment: .top) {
            ForEach(groups) { group in
              HStack {
                ImageView(img: group.icon?.large)
                  .imageStyle(width: 32, height: 32)
                  .imageType(.icon)
                  .imageLink(group.link)
                VStack(alignment: .leading, spacing: 2) {
                  Text(group.title.withLink(group.link))
                    .lineLimit(1)
                    .font(.footnote)
                  Divider()
                  Text("\(group.members ?? 0) 位成员")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .lineLimit(1)
                }
                Spacer()
              }
              .frame(width: 160)
            }
          }.padding(2)
        }
        .scrollClipDisabled()
      }
    }
    .animation(.default, value: refreshing)
    .animation(.default, value: groups)
  }
}
