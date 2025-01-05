import SwiftUI

struct UserSubjectCollectionView: View {
  let stype: SubjectType
  let width: CGFloat

  @Environment(User.self) var user

  @State private var ctype: CollectionType = .collect
  @State private var subjects: [SlimSubjectDTO] = []

  init(_ stype: SubjectType, _ width: CGFloat) {
    self.stype = stype
    self.width = width
  }

  var columnCount: Int {
    let columns = Int((width - 8) / 68)
    return columns > 0 ? columns : 1
  }

  var limit: Int {
    if columnCount >= 7 {
      return min(columnCount, 20)
    } else if columnCount >= 4 {
      return columnCount * 2
    } else {
      return columnCount * 3
    }
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func refresh() async {
    if width == 0 { return }
    do {
      let resp = try await Chii.shared.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: 20)
      subjects = resp.data.map { $0.subject.slim }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      HStack {
        Text("\(user.nickname)的\(stype.description)").font(.title3)
        Spacer()
        NavigationLink(value: NavDestination.userCollection(user.slim, stype)) {
          Text("更多 »")
            .font(.caption)
        }.buttonStyle(.navLink)
      }
      .padding(.top, 8)
      .task(refresh)
      .onChange(of: width) {
        if !subjects.isEmpty {
          return
        }
        Task {
          await refresh()
        }
      }

      Picker("Collection Type", selection: $ctype) {
        ForEach(CollectionType.allTypes()) { ct in
          Text(ct.description(stype)).tag(ct)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: ctype) { _, _ in
        Task {
          await refresh()
        }
      }

      LazyVGrid(columns: columns) {
        ForEach(Array(subjects.prefix(limit))) { subject in
          ImageView(img: subject.images?.resize(.r200))
            .imageStyle(width: 60, height: 60)
            .imageType(.subject)
            .imageLink(subject.link)
        }
      }
    }.animation(.default, value: subjects)
  }
}
