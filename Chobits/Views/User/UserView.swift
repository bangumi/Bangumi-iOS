//
//  UserView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import SwiftUI

struct UserView: View {
  let uid: String

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label

  @State private var user: User?

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/user/\(uid)")!
  }

  func load() async {
    do {
      user = try await Chii.shared.getUser(uid: uid)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    if let user = user {
      ScrollView {
        LazyVStack(alignment: .leading) {
          HStack {
            ImageView(img: user.avatar.large, width: 100, height: 100, type: .avatar)
            VStack(alignment: .leading) {
              Text(user.nickname).font(.title2.bold())
              HStack {
//                BorderView(.secondary, padding: 2) {
//                  Text(user.userGroup.description)
//                    .font(.footnote)
//                    .foregroundStyle(.secondary)
//                }
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
          ShareLink(item: shareLink) {
            Label("Share", systemImage: "square.and.arrow.up")
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

  return UserView(uid: "873244")
    .modelContainer(container)
}
