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
  var personId: UInt

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii

  @State private var refreshed: Bool = false
  @State private var coverDetail = false
  @State private var showSummary: Bool = false
  @State private var showInfobox: Bool = false

  @Query
  private var persons: [Person]
  var person: Person? { persons.first }

  init(personId: UInt) {
    self.personId = personId
    let predicate = #Predicate<Person> {
      $0.personId == personId
    }
    _persons = Query(filter: predicate, sort: \Person.personId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/person/\(personId)")!
  }

  var nameCn: String {
    guard let person = person else {
      return ""
    }
    for item in person.infobox {
      if INFOBOX_NAME_CN_KEYS.contains(item.key) {
        if case .string(let val) = item.value {
          return val
        }
      }
    }
    return ""
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadPerson(personId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
      return
    }
  }

  func refreshAll() async {
    do {
      try await chii.loadPerson(personId)
      try await chii.loadPersonSubjects(personId)
      try await chii.loadPersonCharacters(personId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
      return
    }
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
            HStack(alignment: .bottom) {
              if person.locked {
                Label("", systemImage: "lock")
                  .foregroundStyle(.red)
              }
              Spacer()
              if !isolationMode {
                Label("评论: \(person.stat.comments)", systemImage: "bubble")
                  .font(.footnote)
                  .foregroundStyle(Color("LinkTextColor"))
              }
            }

            /// header
            HStack(alignment: .top) {
              ImageView(img: person.images.medium, width: 100, height: 150, alignment: .top)
                .onTapGesture {
                  coverDetail.toggle()
                }
                .sheet(isPresented: $coverDetail) {
                  ImageView(img: person.images.large, width: 0, height: 0)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.8)])
                }
              VStack(alignment: .leading) {
                HStack {
                  Label(person.typeEnum.description, systemImage: person.typeEnum.icon)
                  Spacer()
                  Text("收藏: \(person.stat.collects)")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                  ForEach(person.infobox, id: \.key) { item in
                    HStack(alignment: .top) {
                        Text("\(item.key):").fixedSize(horizontal: false, vertical: true)
                      switch item.value {
                      case .string(let val):
                        Text(val)
                          .foregroundStyle(.secondary)
                          .textSelection(.enabled)
                          .lineLimit(1)
                      case .list(let vals):
                        VStack(alignment: .leading) {
                          ForEach(vals, id: \.desc) { val in
                            Text(val.desc)
                              .foregroundStyle(.secondary)
                              .textSelection(.enabled)
                              .lineLimit(1)
                          }
                        }
                      }
                    }
                  }
                }
                .font(.footnote)
                .frame(maxHeight: 108, alignment: .top)
                .clipped()
                .sheet(isPresented: $showInfobox) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("资料").font(.title3).padding(.vertical, 10)
                      VStack(alignment: .leading) {
                        ForEach(person.infobox, id: \.key) { item in
                          HStack(alignment: .top) {
                            Text("\(item.key):")
                            switch item.value {
                            case .string(let val):
                              Text(val)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(1)
                            case .list(let vals):
                              VStack(alignment: .leading) {
                                ForEach(vals, id: \.desc) { val in
                                  Text(val.desc)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .lineLimit(1)
                                }
                              }
                            }
                          }
                        }
                      }
                      .presentationDragIndicator(.visible)
                      .presentationDetents([.medium, .large])
                      Spacer()
                    }
                  }.padding()
                }
                Spacer()
                Button(action: {
                  showInfobox.toggle()
                }) {
                  Text("more...")
                    .font(.caption)
                    .foregroundStyle(Color("LinkTextColor"))
                }
              }.padding(.leading, 2)
            }

            /// career
            HStack {
              ForEach(careers, id: \.self) { career in
                Text(career)
                  .padding(.horizontal, 2)
                  .font(.subheadline)
                  .overlay {
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(.gray, lineWidth: 1)
                      .padding(.horizontal, -2)
                      .padding(.vertical, -1)
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
                    }
                  }.padding()
                }
                .overlay(
                  GeometryReader { geometry in
                    if shouldShowToggle(geometry: geometry, limits: 5) {
                      Button(action: {
                        showSummary.toggle()
                      }) {
                        Text("more...")
                          .font(.caption)
                          .foregroundStyle(Color("LinkTextColor"))
                      }
                      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                  }
                )
            }

            /// characters
            PersonCharactersView(personId: personId)

            /// subjects
            PersonSubjectsView(personId: personId)
          }
        }
        .padding(.horizontal, 8)
        .refreshable {
          await refreshAll()
        }
      } else {
        NotFoundView()
      }
    }
    .navigationTitle(person?.name ?? "人物")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        ShareLink(item: shareLink) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
    }
    .onAppear {
      Task(priority: .background) {
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
      .environment(Notifier())
      .environment(ChiiClient(container: container, mock: .anime))
      .modelContainer(container)
  }
}
