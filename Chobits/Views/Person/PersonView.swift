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

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var refreshed: Bool = false
  @State private var coverDetail = false
  @State private var showSummary: Bool = false

  @Query
  private var persons: [Person]
  var person: Person? { persons.first }

  init(personId: UInt) {
    self.personId = personId
    let predicate = #Predicate<Person> {
      $0.id == personId
    }
    _persons = Query(filter: predicate, sort: \Person.id)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/person/\(personId)")!
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

  func shouldShowToggle(geometry: GeometryProxy) -> Bool {
    let lines = Int(
      geometry.size.height / UIFont.preferredFont(forTextStyle: .body).lineHeight)
    if lines < 5 {
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
                    .foregroundStyle(
                      .accent)
                  Spacer()
                  if person.locked {
                    Label("", systemImage: "lock").foregroundStyle(.red)
                  }
                }

                Spacer()
                Text(person.name)
                  .font(.title2.bold())
                  .multilineTextAlignment(.leading)
                  .lineLimit(2)
                Spacer()

                if let gender = person.gender {
                  Label("性别: \(gender)", systemImage: "person.fill").foregroundStyle(.secondary)
                }
                if let bloodType = person.bloodType {
                  Label("血型: \(BloodType(bloodType).name)", systemImage: "heart.fill")
                    .foregroundStyle(.secondary)
                }
                if !person.birthday.isEmpty {
                  Label("生日: \(person.birthday)", systemImage: "calendar").foregroundStyle(
                    .secondary)
                }

                Spacer()
                HStack {
                  Label("收藏: \(person.stat.collects)", systemImage: "heart.fill")
                  Spacer()
                  if !isolationMode {
                    Label("评论: \(person.stat.comments)", systemImage: "bubble")
                  }
                }
                .font(.footnote)
                .foregroundStyle(.accent)
              }
            }

            HStack {
              ForEach(careers, id: \.self) { career in
                Text(career)
                  .padding(.horizontal, 4)
                  .overlay {
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(.gray, lineWidth: 1)
                      .padding(.horizontal, -2)
                      .padding(.vertical, -1)
                  }
              }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            /// summary
            Section {
              Text(person.summary)
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
                    if shouldShowToggle(geometry: geometry) {
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
          }
        }.padding(.horizontal, 8)
      } else {
        NotFoundView()
      }
    }
    .navigationTitle(person?.name ?? "人物")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
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

  return PersonView(personId: person.id)
    .environmentObject(Notifier())
    .environment(ChiiClient(container: container, mock: .anime))
    .modelContainer(container)
}
