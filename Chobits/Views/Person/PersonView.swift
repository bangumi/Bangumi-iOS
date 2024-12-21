import Flow
import OSLog
import SwiftData
import SwiftUI

struct PersonView: View {
  var personId: Int

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var refreshed: Bool = false

  @Query private var persons: [Person]
  var person: Person? { persons.first }

  init(personId: Int) {
    self.personId = personId
    let predicate = #Predicate<Person> {
      $0.personId == personId
    }
    _persons = Query(filter: predicate, sort: \Person.personId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/person/\(personId)")!
  }

  var nameCN: String {
    guard let person = person else {
      return ""
    }
    if person.nameCN.isEmpty {
      return person.name
    }
    return person.nameCN
  }

  var careers: [String] {
    guard let person = person else { return [] }
    let vals = Set(person.career).sorted().map { PersonCareer($0).description }
    return Array(vals)
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadPerson(personId)

      Task {
        let respCasts = try await Chii.shared.getPersonCasts(personId, limit: 5)
        person?.casts = respCasts.data
      }

      Task {
        let respWorks = try await Chii.shared.getPersonWorks(personId, limit: 5)
        person?.works = respWorks.data
      }

    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  var body: some View {
    Section {
      if let person = person {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {

            /// title
            Text(person.name)
              .font(.title2.bold())
              .multilineTextAlignment(.leading)

            /// header
            HStack(alignment: .top) {
              ImageView(img: person.images?.large, large: person.images?.large)
                .imageStyle(width: 120, height: 160, alignment: .top)
                .imageType(.person)
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: person.typeEnum.icon)
                  if person.collects > 0 {
                    Text("(\(person.collects)人收藏)").lineLimit(1)
                  }
                  Spacer()
                  // if person.lock {
                  //   Label("", systemImage: "lock")
                  //     .foregroundStyle(.red)
                  // }
                  if !isolationMode {
                    Label("评论: \(person.comment)", systemImage: "bubble")
                      .lineLimit(1)
                      .font(.footnote)
                  }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
                Text(nameCN)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                  .textSelection(.enabled)
                Spacer()

                NavigationLink(value: NavDestination.infobox("人物信息", person.infobox)) {
                  HStack {
                    InfoboxHeaderView(infobox: person.infobox)
                    Spacer()
                    Image(systemName: "chevron.right")
                  }
                }.buttonStyle(.navLink)

              }.padding(.leading, 2)
            }.frame(height: 160)

            /// career
            HFlow {
              ForEach(careers, id: \.self) { career in
                BorderView {
                  Text(career)
                }
              }
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)

            /// summary
            BBCodeWebView(person.summary, textSize: 14)

            /// casts
            PersonCastsView(personId: personId, casts: person.casts)

            /// works
            PersonWorksView(personId: personId, works: person.works)

          }.padding(.horizontal, 8)
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(person?.name ?? "人物")
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

#Preview {
  let container = mockContainer()

  let person = Person.preview
  container.mainContext.insert(person)

  return NavigationStack {
    PersonView(personId: person.personId)
      .modelContainer(container)
  }
}
