//
//  PersonSubjectListView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/13.
//

import SwiftData
import SwiftUI

struct PersonSubjectListView: View {
  let personId: UInt

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var subjectType: SubjectType = .unknown
  @State private var subjects: [PersonRelatedSubject] = []

  func load() async {
    let stype = subjectType.rawValue
    let zero: UInt8 = 0
    let descriptor = FetchDescriptor<PersonRelatedSubject>(
      predicate: #Predicate<PersonRelatedSubject> {
        if stype == zero {
          return $0.personId == personId
        } else {
          return $0.personId == personId && $0.type == stype
        }
      }, sortBy: [SortDescriptor<PersonRelatedSubject>(\.subjectId, order: .reverse)])
    do {
      subjects = try modelContext.fetch(descriptor)
    } catch {
      notifier.alert(error: error)
    }
  }

  var body: some View {
    Picker("Subject Type", selection: $subjectType) {
      ForEach(SubjectType.allCases) { type in
        Text(type.description).tag(type)
      }
    }
    .padding(.horizontal, 8)
    .pickerStyle(.segmented)
    .onAppear {
      Task {
        await load()
      }
    }
    .onChange(of: subjectType) { _, _ in
      Task {
        await load()
      }
    }
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(subjects) { subject in
          NavigationLink(value: NavDestination.subject(subjectId: subject.subjectId)) {
            HStack {
              ImageView(img: subject.image, width: 60, height: 60, type: .subject)
              VStack(alignment: .leading) {
                Text(subject.name)
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                Text(subject.nameCn)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                Label(subject.staff, systemImage: subject.typeEnum.icon)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
          }.buttonStyle(.plain)
        }
      }
    }
    .padding(.horizontal, 8)
    .buttonStyle(.plain)
    .animation(.default, value: subjects)
    .navigationTitle("参与作品")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  let personSubjects = PersonRelatedSubject.preview
  container.mainContext.insert(person)
  for item in personSubjects {
    container.mainContext.insert(item)
  }

  return PersonSubjectListView(personId: person.personId)
    .environment(Notifier())
    .modelContainer(container)
}
