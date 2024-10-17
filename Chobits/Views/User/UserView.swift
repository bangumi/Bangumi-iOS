//
//  UserView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import SwiftUI

struct UserView: View {
  let uid: String

  @Environment(Notifier.self) private var notifier

  @State private var user: User?

  func load() async {
    do {
      user = try await Chii.shared.getUser(uid: uid)
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    if let user = user {
      ScrollView {
        LazyVStack(alignment: .leading) {
          HStack {
            ImageView(img: user.avatar.large, width: 60, height: 60, type: .avatar)
            VStack(alignment: .leading) {
              Spacer()
              Text(user.nickname).font(.title2.bold())
              Spacer()
              HStack {
                BorderView(.secondary, padding: 2) {
                  Text(user.userGroup.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                if user.username != "" {
                  Text("@\(user.username)")
                } else {
                  Text("@\(user.id)")
                }
              }
              .padding(.leading, 2)
              .foregroundStyle(.secondary)
              .font(.footnote)
              Spacer()
            }
            .padding(.leading, 2)
          }
          if user.sign != "" {
            Text(user.sign)
              .font(.footnote)
              .padding(.vertical, 1)
          }
          Divider().padding(.vertical, 1)
          Text("时光机 🚧")
        }.padding(.horizontal, 8)
      }
      .navigationTitle("\(user.nickname)")
      .navigationBarTitleDisplayMode(.inline)
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
    .environment(Notifier())
    .modelContainer(container)
}
