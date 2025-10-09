import SwiftUI

struct UserSubjectCollectionView: View {
  let stype: SubjectType
  let ctypes: [CollectionType: Int]

  @Environment(User.self) var user

  @State private var ctype: CollectionType
  @State private var refreshing = false
  @State private var subjects: [SlimSubjectDTO] = []

  init(_ stype: SubjectType, _ ctypes: [CollectionType: Int]) {
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

  func refresh() async {
    if refreshing { return }
    refreshing = true
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
                  .lineLimit(1)
                  .font(.footnote)
                  .foregroundStyle(.linkText)
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
          if !subjects.isEmpty {
            return
          }
          await refresh()
        }
        Divider()

        if refreshing {
          HStack {
            Spacer()
            ProgressView().padding()
            Spacer()
          }
        } else {
          ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
              ForEach(subjects) { subject in
                VStack {
                  ImageView(img: subject.images?.resize(.r200))
                    .imageStyle(width: 60, height: imageHeight)
                    .imageType(.subject)
                    .imageLink(subject.link)
                    .subjectPreview(subject)
                    .shadow(radius: 2)
                  Text(subject.name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                }.frame(width: 64)
              }
            }.padding(2)
          }
        }
      }
      .animation(.default, value: ctype)
      .animation(.default, value: refreshing)
      .animation(.default, value: subjects)
    }
  }
}
