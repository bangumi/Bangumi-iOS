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
  @State private var showSign: Bool = false

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
          Text(user.nickname).font(.title2.bold())
          HStack {
            Text(user.userGroup.description)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.secondary, lineWidth: 1)
                  .padding(.horizontal, -2)
                  .padding(.vertical, -1)
              }
            if user.username != "" {
              Text("@\(user.username)")
            } else {
              Text("@\(user.id)")
            }
          }
          .padding(.leading, 5)
          .foregroundStyle(.secondary)
          .font(.footnote)
          HStack {
            ImageView(img: user.avatar.large, width: 60, height: 60, type: .avatar)
            VStack(alignment: .leading) {
              Text(user.sign)
                .font(.footnote)
                .lineLimit(3)
                .sheet(isPresented: $showSign) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text(user.sign)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                      Spacer()
                    }
                  }.padding()
                }
              HStack {
                Spacer()
                Button(action: {
                  showSign.toggle()
                }) {
                  Text("more...")
                    .font(.caption)
                    .foregroundStyle(.linkText)
                }
              }
            }
            .padding(.leading, 2)
          }
          Divider().padding(.vertical, 2)
          Text("时光机 🚧")
        }
      }
      .navigationTitle("\(user.nickname)")
      .navigationBarTitleDisplayMode(.inline)
      .padding(.horizontal, 8)
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
