//
//  PersonSubjectsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/12.
//

import SwiftData
import SwiftUI

struct PersonSubjectsView: View {
  var personId: UInt

  @Query
  private var subjects: [PersonRelatedSubject]

  @State private var refreshed: Bool = false

  init(personId: UInt) {
    self.personId = personId
    var descriptor = FetchDescriptor<PersonRelatedSubject>(
      predicate: #Predicate<PersonRelatedSubject> {
        $0.personId == personId
      }, sortBy: [SortDescriptor<PersonRelatedSubject>(\.subjectId, order: .reverse)])
    descriptor.fetchLimit = 5
    _subjects = Query(descriptor)
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await Chii.shared.loadPersonSubjects(personId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      if subjects.count > 0 {
        Divider()
        HStack {
          Text("最近参与").font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.personSubjectList(personId: personId)) {
            Text("更多作品 »").font(.caption).foregroundStyle(.linkText)
          }.buttonStyle(.plain)
        }
      } else if !refreshed {
        ProgressView()
          .onAppear {
            Task {
              await refresh()
            }
          }
      }

      ForEach(subjects, id: \.subjectId) { subject in
        NavigationLink(value: NavDestination.subject(subjectId: subject.subjectId)) {
          ImageView(img: subject.image, width: 60, height: 60, type: .subject)
          VStack(alignment: .leading) {
            Text(subject.name)
              .foregroundStyle(.linkText)
              .lineLimit(1)
            HStack {
              BorderView(.secondary, padding: 2) {
                Text(subject.staff)
              }
              if !subject.typeEnum.icon.isEmpty {
                Image(systemName: subject.typeEnum.icon)
              }
              Text(subject.nameCn)
                .lineLimit(1)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            Spacer()
          }
        }.buttonStyle(.plain)
      }
    }.animation(.default, value: subjects)
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  container.mainContext.insert(person)

  return ScrollView(showsIndicators: false) {
    LazyVStack(alignment: .leading) {
      PersonSubjectsView(personId: person.personId)
        .modelContainer(container)
    }.padding(.horizontal, 8)
  }
}
