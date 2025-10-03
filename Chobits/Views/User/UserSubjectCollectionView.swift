import SwiftUI

struct UserSubjectCollectionView: View {
  let width: CGFloat
  let stype: SubjectType
  let ctypes: [CollectionType: Int]

  @Environment(User.self) var user

  @State private var ctype: CollectionType
  @State private var refreshing = false
  @State private var subjects: [SlimSubjectDTO] = []

  init(_ width: CGFloat, _ stype: SubjectType, _ ctypes: [CollectionType: Int]) {
    self.width = width
    self.stype = stype
    self.ctypes = ctypes
    self._ctype = State(initialValue: .collect)
    for ct in CollectionType.timelineTypes() {
      if let count = ctypes[ct], count > 0 {
        self._ctype = State(initialValue: ct)
        break
      }
    }
  }

  var imageHeight: CGFloat {
    switch stype {
    case .music:
      return 60
    default:
      return 80
    }
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
    if refreshing { return }
    refreshing = true
    if width == 0 { return }
    do {
      let resp = try await Chii.shared.getUserSubjectCollections(
        username: user.username, type: ctype, subjectType: stype, limit: 20)
      subjects = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  var body: some View {
    if ctypes.isEmpty {
      EmptyView()
    } else {
      VStack {
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .bottom, spacing: 2) {
            NavigationLink(value: NavDestination.userCollection(user.slim, stype, ctypes)) {
              Text(stype.description).font(.title3)
            }
            .buttonStyle(.navigation)
            .padding(.horizontal, 4)

            ForEach(CollectionType.allTypes(), id: \.self) { ct in
              if let count = ctypes[ct], count > 0 {
                let borderColor = ctype == ct ? Color.linkText : Color.secondary.opacity(0.2)
                BorderView(color: borderColor, padding: 3, cornerRadius: 16) {
                  Text("\(ct.description(stype)) \(count)")
                    .font(.footnote)
                    .foregroundStyle(.linkText)
                    .monospacedDigit()
                }
                .padding(1)
                .onTapGesture {
                  if ctype == ct {
                    return
                  }
                  Task {
                    ctype = ct
                    await refresh()
                  }
                }
              }
            }

            Spacer(minLength: 0)
          }
          .padding(.top, 8)
          .task {
            await refresh()
          }
          .onChange(of: width) {
            if !subjects.isEmpty {
              return
            }
            Task {
              await refresh()
            }
          }
          Divider()
        }

        if refreshing {
          ProgressView()
        } else {
          LazyVGrid(columns: columns) {
            ForEach(Array(subjects.prefix(limit))) { subject in
              ImageView(img: subject.images?.resize(.r200))
                .imageStyle(width: 60, height: imageHeight)
                .imageType(.subject)
                .imageLink(subject.link)
                .subjectPreview(subject)
            }
          }
        }
      }.animation(.default, value: subjects)
    }
  }
}
