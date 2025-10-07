import SwiftUI

enum IndexListType: CaseIterable {
  case created
  case collect

  var title: String {
    switch self {
    case .created:
      return "创建的目录"
    case .collect:
      return "收藏的目录"
    }
  }
}

struct UserIndexListView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  @State private var reloader = false
  @State private var type: IndexListType = .created
  @State private var showCreateIndex = false

  var title: String {
    if user.username == profile.username {
      return "我\(type.title)"
    } else {
      return "\(user.nickname)\(type.title)"
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimIndexDTO>? {
    do {
      let resp = try await {
        switch type {
        case .collect:
          let data = try await Chii.shared.getUserIndexCollections(
            username: user.username, limit: limit, offset: offset)
          return data
        case .created:
          return try await Chii.shared.getUserIndexes(
            username: user.username, limit: limit, offset: offset)
        }
      }()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      Picker("Type", selection: $type) {
        ForEach(IndexListType.allCases, id: \.self) { type in
          Text(type.title).tag(type)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)
      .onChange(of: type) { _, _ in
        reloader.toggle()
      }
      ScrollView {
        PageView<SlimIndexDTO, _>(reloader: reloader, nextPageFunc: load) { item in
          CardView {
            UserIndexItemView(index: item)
          }
        }.padding(8)
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if user.username == profile.username && type == .created {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showCreateIndex = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
    }
    .sheet(isPresented: $showCreateIndex) {
      IndexEditView {
        reloader.toggle()
      }
    }
  }
}
