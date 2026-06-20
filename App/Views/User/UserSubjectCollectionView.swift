import SwiftUI

struct UserSubjectCollectionView: View {
  let user: UserDTO
  let stype: SubjectType
  let ctypes: [CollectionType: Int]

  @State private var ctype: CollectionType
  @State private var refreshing = false
  @State private var subjects: [SlimSubjectDTO] = []

  init(user: UserDTO, stype: SubjectType, ctypes: [CollectionType: Int]) {
    self.user = user
    self.stype = stype
    self.ctypes = ctypes
    self._ctype = State(
      initialValue: CollectionType.preferredAvailableType(in: ctypes) ?? .collect)
  }

  func refresh() async {
    if refreshing { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let resp = try await UserService.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: 20)
      withAnimation(.default) {
        subjects = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      refreshing = false
    }
  }

  var body: some View {
    if ctypes.isEmpty {
      EmptyView()
    } else {
      SubjectCollectionSectionView(
        title: stype.description,
        destination: NavDestination.userCollection(user.slim, stype, ctypes),
        subjectType: stype,
        counts: ctypes,
        selection: $ctype,
        subjects: subjects,
        refreshing: refreshing
      )
      .onChange(of: ctype) { _, _ in
        Task {
          await refresh()
        }
      }
      .task {
        if !subjects.isEmpty {
          return
        }
        await refresh()
      }
    }
  }
}
