//
//  UserView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import SwiftUI

struct UserView: View {
  let username: String

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label

  @State private var user: User?

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/user/\(username)")!
  }

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
            ImageView(img: user.avatar?.large, width: 100, height: 100, type: .avatar)
            VStack(alignment: .leading) {
              Text(user.nickname).font(.title2.bold())
              HStack {
                // BorderView {
                //   Text(user.userGroup.description)
                //     .font(.footnote)
                //     .foregroundStyle(.secondary)
                // }
                if user.username != "" {
                  Text("@\(user.username)")
                } else {
                  Text("@\(user.id)")
                }
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
          Divider()
          Text("时光机 🚧")
        }.padding(.horizontal, 8)
      }
      .navigationTitle("\(user.nickname)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            ShareLink(item: shareLink) {
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
