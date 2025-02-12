import SwiftData
import SwiftUI

struct GroupView: View {
  let name: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var refreshed: Bool = false

  @Query private var groups: [Group]
  var group: Group? { groups.first }

  init(name: String) {
    self.name = name
    let predicate = #Predicate<Group> {
      $0.name == name
    }
    _groups = Query(filter: predicate, sort: \Group.groupId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/group/\(name)")!
  }

  var title: String {
    guard let group = group else {
      return "小组"
    }
    return group.title
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadGroup(name)
      refreshed = true
      try await Chii.shared.loadGroupDetails(name)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let group = group {
        GroupDetailView()
          .environment(group)
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(title)
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
    .onAppear {
      Task {
        await refresh()
      }
    }
  }
}

struct GroupDetailView: View {
  @Environment(Group.self) var group

  var body: some View {
    Text(group.title)
  }
}
