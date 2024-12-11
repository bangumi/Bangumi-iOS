//
//  PersonView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import OSLog
import SwiftData
import SwiftUI

struct PersonView: View {
  var personId: Int

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var refreshed: Bool = false
  @State private var showSummary: Bool = false

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
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  func shouldShowToggle(
    _ geometry: GeometryProxy,
    font: UIFont.TextStyle = .body, limits: Int = 5
  )
    -> Bool
  {
    let lines = Int(
      geometry.size.height / UIFont.preferredFont(forTextStyle: font).lineHeight)
    if lines < limits {
      return false
    }
    return true
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
              ImageView(img: person.images?.medium, width: 120, height: 160, alignment: .top)
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
                      .foregroundStyle(.linkText)
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

                NavigationLink(value: NavDestination.personInfobox(person: person)) {
                  HStack {
                    InfoboxHeaderView(infobox: person.infobox)
                      .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.linkText)
                  }
                }
                .buttonStyle(.plain)

              }.padding(.leading, 2)
            }.frame(height: 160)

            /// career
            HStack {
              ForEach(careers, id: \.self) { career in
                BorderView {
                  Text(career)
                    .font(.subheadline)
                }
              }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            /// summary
            Text(person.summary.bbcode)
              .padding(.bottom, 16)
              .multilineTextAlignment(.leading)
              .lineLimit(5)
              .sheet(isPresented: $showSummary) {
                ScrollView {
                  LazyVStack(alignment: .leading) {
                    BBCodeView(person.summary)
                    Divider()
                  }.padding()
                }
              }
              .overlay(
                GeometryReader { geometry in
                  if shouldShowToggle(geometry, font: .footnote) {
                    Button(action: {
                      showSummary.toggle()
                    }) {
                      Text("more...")
                        .font(.caption)
                        .foregroundStyle(.linkText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                  }
                }
              )

            /// casts
            PersonCastsView(personId: personId)

            /// works
            PersonWorksView(personId: personId)

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
