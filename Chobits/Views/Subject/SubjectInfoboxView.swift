//
//  SubjectInfoboxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import OSLog
import SwiftData
import SwiftUI

enum SubjectStaffItem: Identifiable {
  case plain(String)
  case person(SubjectRelatedPerson)

  var id: String {
    switch self {
    case .plain(let val):
      return val
    case .person(let person):
      return person.name
    }
  }
}

struct SubjectInfoboxItem: Identifiable {
  var relation: String
  var staffs: [SubjectStaffItem]
  var long: Bool

  var id: String {
    self.relation
  }

  init(relation: String, staffs: [SubjectStaffItem], long: Bool = false) {
    self.relation = relation
    self.staffs = staffs
    self.long = long
  }
}

struct SubjectInfoboxView: View {
  let subjectId: UInt

  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii
  @Environment(\.modelContext) var modelContext

  @State private var refreshed: Bool = false
  @State private var persons: [SubjectRelatedPerson] = []

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      }, sort: \Subject.subjectId)
  }

  func load() async {
    let fetcher = BackgroundFetcher(modelContext.container)
    let descriptor = FetchDescriptor<SubjectRelatedPerson>(
      predicate: #Predicate<SubjectRelatedPerson> {
        $0.subjectId == subjectId
      }, sortBy: [SortDescriptor<SubjectRelatedPerson>(\.sort)])
    do {
      self.persons = try await fetcher.fetchData(descriptor)
    } catch {
      notifier.alert(error: error)
    }
  }

  func checkRefresh() async {
    if refreshed { return }
    refreshed = true
    if persons.count > 0 {
      return
    }
    await refresh()
  }

  func refresh() async {
    do {
      try await chii.loadSubjectPersons(subjectId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
    }
    await load()
  }

  var subjectStaffs: [String: [SubjectRelatedPerson]] {
    Dictionary(grouping: persons, by: \.relation)
  }

  var infoList: [SubjectInfoboxItem] {
    guard let subject = subject else { return [] }
    var items: [String: [SubjectStaffItem]] = [:]
    let infoboxKeys = subject.infobox.map { $0.key }
    for item in subject.infobox {
      var staffs: [SubjectStaffItem] = []
      let relatedPersons = subjectStaffs[item.key, default: []]
      let personNames = relatedPersons.map { $0.name }
      switch item.value {
      case .string(let val):
        if !personNames.contains(val) {
          staffs.append(.plain((val)))
        }
      case .list(let vals):
        for val in vals {
          if !personNames.contains(val.v) {
            if let k = val.k {
              staffs.append(.plain(("\(k): \(val.v)")))
            } else {
              staffs.append(.plain((val.v)))
            }
          }
        }
      }
      items[item.key] = staffs
    }
    for person in persons {
      if items.keys.contains(person.relation) {
        items[person.relation]?.append(.person(person))
      } else {
        items[person.relation] = [.person(person)]
      }
    }
    var result: [SubjectInfoboxItem] = []
    for item in subject.infobox {
      if let staffs = items[item.key] {
        let plainStaffs = staffs.filter {
          if case .plain = $0 {
            return true
          } else {
            return false
          }
        }
        if plainStaffs.count <= 1 || item.key == "别名" {
          result.append(SubjectInfoboxItem(relation: item.key, staffs: staffs, long: true))
        } else {
          result.append(SubjectInfoboxItem(relation: item.key, staffs: staffs))
        }
      }
    }
    for item in items {
      if !infoboxKeys.contains(item.key) {
        result.append(SubjectInfoboxItem(relation: item.key, staffs: item.value))
      }
    }
    return result
  }

  var body: some View {
    Section {
      ScrollView {
        LazyVStack(alignment: .leading) {
          ForEach(infoList) { info in
            HStack(alignment: .top) {
              Text("\(info.relation):").bold()
              if info.long {
                let plains = info.staffs.filter {
                  if case .plain = $0 {
                    return true
                  } else {
                    return false
                  }
                }
                let links = info.staffs.filter {
                  if case .person = $0 {
                    return true
                  } else {
                    return false
                  }
                }
                VStack(alignment: .leading) {
                  ForEach(plains) { staff in
                    Text(staff.id).textSelection(.enabled)
                  }
                  FlowStack {
                    ForEach(Array(links.enumerated()), id: \.offset) { idx, staff in
                      if idx > 0 {
                        Text("、")
                      }
                      switch staff {
                      case .plain(let name):
                        Text(name).lineLimit(1).textSelection(.enabled)
                      case .person(let person):
                        NavigationLink(value: NavDestination.person(personId: person.personId)) {
                          Text(person.name).lineLimit(1)
                        }.buttonStyle(.plain).foregroundStyle(Color("LinkTextColor"))
                      }
                    }
                  }
                }
              } else {
                FlowStack {
                  ForEach(Array(info.staffs.enumerated()), id: \.offset) { idx, staff in
                    if idx > 0 {
                      Text("、")
                    }
                    switch staff {
                    case .plain(let name):
                      Text(name).lineLimit(1).textSelection(.enabled)
                    case .person(let person):
                      NavigationLink(value: NavDestination.person(personId: person.personId)) {
                        Text(person.name).lineLimit(1)
                      }.buttonStyle(.plain).foregroundStyle(Color("LinkTextColor"))
                    }
                  }
                }
              }
            }
            Divider()
          }
        }
      }
      .refreshable {
        await refresh()
      }
      .padding(.horizontal, 8)
    }
    .animation(.default, value: persons)
    .navigationTitle("条目信息")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "info.circle").foregroundStyle(.secondary)
      }
    }
    .onAppear {
      Task(priority: .background) {
        await load()
        await checkRefresh()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectInfoboxView(subjectId: subject.subjectId)
        .environment(Notifier())
        .environment(ChiiClient(container: container, mock: .anime))
        .modelContainer(container)
    }
  }.padding()
}
