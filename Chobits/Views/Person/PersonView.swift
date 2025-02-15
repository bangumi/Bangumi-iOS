import BBCode
import OSLog
import SwiftData
import SwiftUI

struct PersonView: View {
  var personId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var refreshed: Bool = false

  @Query private var persons: [Person]
  var person: Person? { persons.first }

  @State private var comments: [CommentDTO] = []

  init(personId: Int) {
    self.personId = personId
    let predicate = #Predicate<Person> {
      $0.personId == personId
    }
    _persons = Query(filter: predicate, sort: \Person.personId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/person/\(personId)")!
  }

  var title: String {
    guard let person = person else {
      return "人物"
    }
    return person.name
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadPerson(personId)
      refreshed = true

      if !isolationMode {
        comments = try await Chii.shared.getPersonComments(personId)
      }

      try await Chii.shared.loadPersonDetails(personId)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let person = person {
        ScrollView {
          LazyVStack(alignment: .leading) {
            PersonDetailView()
              .environment(person)

            /// comments
            if !isolationMode {
              LazyVStack(alignment: .leading, spacing: 8) {
                Text("吐槽箱").font(.title3)
                Divider()
                ForEach(comments) { comment in
                  CommentItemView(comment: comment)
                  if comment.id != comments.last?.id {
                    Divider()
                  }
                }
              }
            }
          }.padding(.horizontal, 8)
        }
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

struct PersonDetailView: View {
  @Environment(Person.self) var person

  @AppStorage("isolationMode") var isolationMode: Bool = false

  var careers: String {
    let vals = Set(person.career).sorted().map { PersonCareer($0).description }
    return vals.joined(separator: " / ")
  }

  var body: some View {
    /// title
    Text(person.name)
      .font(.title2.bold())
      .multilineTextAlignment(.leading)

    /// header
    HStack(alignment: .top) {
      ImageView(img: person.images?.resize(.r400))
        .imageStyle(width: 120, height: 160, alignment: .top)
        .imageType(.person)
        .enableSave(person.images?.large)
        .padding(4)
        .shadow(radius: 4)
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
        Text(person.title)
          .multilineTextAlignment(.leading)
          .truncationMode(.middle)
          .lineLimit(2)
          .textSelection(.enabled)
        Spacer()

        if !careers.isEmpty {
          Text(careers)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        NavigationLink(value: NavDestination.infobox("人物信息", person.infobox)) {
          InfoboxHeaderView(infobox: person.infobox)
        }.buttonStyle(.plain)

      }.padding(.leading, 2)
    }.frame(height: 160)

    /// summary
    BBCodeView(person.summary, textSize: 14)
      .textSelection(.enabled)
      .padding(2)
      .tint(.linkText)

    /// casts
    PersonCastsView(personId: person.personId, casts: person.casts)

    /// works
    PersonWorksView(personId: person.personId, works: person.works)
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
