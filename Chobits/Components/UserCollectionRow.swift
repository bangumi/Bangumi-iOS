//
//  UserCollectionRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftData
import SwiftUI

struct UserCollectionRow: View {
  let collection: UserSubjectCollectionItem

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(collection: UserSubjectCollectionItem) {
    self.collection = collection

    let subjectId = collection.subjectId
    let predicate = #Predicate<Subject> {
      $0.id == subjectId
    }
    _subjects = Query(filter: predicate, sort: \Subject.id)
  }

  var epsColor: Color {
    collection.epStatus == 0 ? .secondary : .accent
  }

  var volsColor: Color {
    collection.volStatus == 0 ? .secondary : .accent
  }

  var chapters: String {
    guard let subject = subject else { return "" }
    if subject.eps > 0 {
      return "/ \(subject.eps) 话"
    } else {
      return "/ ? 话"
    }
  }

  var volumes: String {
    guard let subject = subject else { return "" }
    if subject.volumes > 0 {
      return "/ \(subject.volumes) 卷"
    } else {
      return "/ ? 卷"
    }
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.accent)
        .opacity(0.01)
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .accent, radius: 1, x: 1, y: 1)
      HStack(alignment: .top) {
        ImageView(img: subject?.images.common, width: 60, height: 60)
        VStack(alignment: .leading) {
          Text(subject?.name ?? "").font(.headline)
          Text(subject?.nameCn ?? "").font(.footnote).foregroundStyle(.secondary)
          HStack {
            Text(collection.updatedAt).foregroundStyle(.secondary)
            if collection.private {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            Spacer()
            switch collection.subjectType {
            case .anime:
              Text("\(collection.epStatus)").foregroundStyle(epsColor).font(.callout)
              Text(chapters).foregroundStyle(epsColor)
            case .book:
              Text("\(collection.epStatus)").foregroundStyle(epsColor).font(.callout)
              Text("\(chapters)").foregroundStyle(epsColor)
              Text("\(collection.volStatus)").foregroundStyle(volsColor).font(.callout)
              Text("\(volumes)").foregroundStyle(volsColor)
            case .real:
              Text("\(collection.epStatus)").foregroundStyle(epsColor).font(.callout)
              Text(chapters).foregroundStyle(epsColor)
            default:
              Label(
                collection.subjectType.description,
                systemImage: collection.subjectType.icon
              )
              .foregroundStyle(.accent)
            }
          }.font(.caption)
        }
        Spacer()
      }
      .frame(height: 60)
      .padding(2)
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: Subject.self, UserSubjectCollection.self, configurations: config)

  let collection = UserSubjectCollection.previewBook
  let subject = Subject.previewBook

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      UserCollectionRow(collection: collection.item)
        .environmentObject(Notifier())
    }
  }
  .padding()
  .modelContainer(container)
}
