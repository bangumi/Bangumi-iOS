import BBCode
import Flow
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
          Text(user.nickname)
            .font(.title3)
            .fontWeight(.bold)
            .padding(.top, 8)

          /// header
          HStack {
            ImageView(img: user.avatar?.large)
              .imageStyle(width: 100, height: 100)
              .imageType(.avatar)
            VStack(alignment: .leading) {

              HStack(spacing: 5) {
                BadgeView {
                  Text(user.group.description)
                    .font(.caption)
                }
                Text("@\(user.username)")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .textSelection(.enabled)
              }

              HStack(spacing: 5) {
                BadgeView {
                  Text("Bangumi")
                    .font(.caption)
                    .fixedSize()
                }
                Text("\(user.joinedAt.dateDisplay)加入")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }

              Divider()
              Text(user.sign)
                .font(.footnote)
                .textSelection(.enabled)

            }
          }.frame(height: 100)

          /// user bio
          if user.bio.isEmpty {
            Divider()
          } else {
            CardView {
              HStack {
                BBCodeView(user.bio, textSize: 12)
                  .tint(.linkText)
                  .textSelection(.enabled)
                Spacer()
              }
            }
          }

          HFlow {
            ForEach(user.networkServices) { service in
              HStack(spacing: 5) {
                BadgeView(background: Color(service.color)) {
                  Text(service.title)
                    .font(.caption)
                    .fixedSize()
                }
                Text(service.account.withLink(service.link))
                  .font(.footnote)
                  .textSelection(.enabled)
              }
            }
          }

          Text("时光机 🚧")
        }.padding(.horizontal, 8)
      }
      .navigationTitle("\(user.nickname)")
      .toolbarTitleDisplayMode(.inline)
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
