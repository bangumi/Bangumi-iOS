import BBCode
import SwiftUI

struct UserView: View {
  let username: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var user: UserDTO?

  func load() async {
    do {
      user = try await Chii.shared.getUser(username)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    if let user = user {
      ScrollView {
        LazyVStack(alignment: .leading) {
          HStack {
            ImageView(img: user.avatar?.large)
              .imageStyle(width: 100, height: 100)
              .imageType(.avatar)
            VStack(alignment: .leading) {
              Text(user.nickname).font(.title2.bold())
              HStack {
                // BorderView {
                //   Text(user.userGroup.description)
                //     .font(.footnote)
                //     .foregroundStyle(.secondary)
                // }
                Text("@\(user.username)")
              }
              .foregroundStyle(.secondary)
              .font(.footnote)
              if user.sign != "" {
                Text(user.sign)
                  .font(.footnote)
              }
            }
            .padding(.leading, 2)
          }
          if user.bio.isEmpty {
            Divider()
          } else {
            CardView {
              HStack {
                BBCodeView(user.bio)
                Spacer()
              }
            }
          }

          Text("时光机 🚧")
        }.padding(.horizontal, 8)
      }
      .navigationTitle("\(user.nickname)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            ShareLink(item: user.link) {
              Label("分享", systemImage: "square.and.arrow.up")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    } else {
      ProgressView()
        .task {
          await load()
        }
    }
  }
}

#Preview {
  let container = mockContainer()

  return UserView(username: "873244")
    .modelContainer(container)
}
