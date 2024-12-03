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
  @State private var showInfobox: Bool = false

  @Query
  private var persons: [Person]
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

  func shouldShowToggle(geometry: GeometryProxy, limits: Int) -> Bool {
    let lines = Int(
      geometry.size.height / UIFont.preferredFont(forTextStyle: .body).lineHeight)
    if lines < limits {
      return false
    }
    return true
  }

  var careers: [String] {
    guard let person = person else { return [] }
    let vals = Set(person.career).sorted().map { PersonCareer($0).description }
    return Array(vals)
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
                  Label(person.typeEnum.description, systemImage: person.typeEnum.icon)
                  if person.collects > 0 {
                    Text("(\(person.collects)人收藏)")
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
                VStack(alignment: .leading) {
                  ForEach(person.infobox, id: \.key) { item in
                    HStack(alignment: .top) {
                      Text("\(item.key):").fixedSize(horizontal: false, vertical: true)
                      VStack(alignment: .leading) {
                        ForEach(item.values, id: \.v) { value in
                          HStack {
                            if let k = value.k {
                              Text("\(k):")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            }
                            Text(value.v)
                              .textSelection(.enabled)
                              .lineLimit(1)
                          }
                        }
                      }
                    }
                  }
                }
                .font(.footnote)
                .frame(maxHeight: 110, alignment: .top)
                .clipped()
                .sheet(isPresented: $showInfobox) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("资料").font(.title3).padding(.vertical, 10)
                      VStack(alignment: .leading) {
                        ForEach(person.infobox, id: \.key) { item in
                          HStack(alignment: .top) {
                            Text("\(item.key):").fixedSize(horizontal: false, vertical: true)
                            VStack(alignment: .leading) {
                              ForEach(item.values, id: \.v) { value in
                                HStack {
                                  if let k = value.k {
                                    Text("\(k):")
                                      .font(.caption)
                                      .foregroundStyle(.secondary)
                                      .lineLimit(1)
                                  }
                                  Text(value.v)
                                    .textSelection(.enabled)
                                    .lineLimit(1)
                                }
                              }
                            }
                          }
                          Divider()
                        }
                      }
                      .presentationDragIndicator(.visible)
                      Spacer()
                    }.padding()
                  }
                }
                Spacer()
                Button(action: {
                  showInfobox.toggle()
                }) {
                  Text("more...")
                    .font(.caption)
                    .foregroundStyle(.linkText)
                }
              }.padding(.leading, 2)
            }

            /// career
            HStack {
              ForEach(careers, id: \.self) { career in
                BorderView(.secondary, padding: 2) {
                  Text(career)
                    .font(.subheadline)
                }
              }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            /// summary
            Section {
              Text(person.summary)
                .font(.footnote)
                .padding(.bottom, 16)
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .sheet(isPresented: $showSummary) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("简介").font(.title3).padding(.vertical, 10)
                      Text(person.summary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                      Spacer()
                    }.padding()
                  }
                }
                .overlay(
                  GeometryReader { geometry in
                    if shouldShowToggle(geometry: geometry, limits: 5) {
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
            }

            /// casts
            // PersonCastsView(personId: personId)

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
