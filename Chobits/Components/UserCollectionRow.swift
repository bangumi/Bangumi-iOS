//
//  UserCollectionRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftData
import SwiftUI

struct UserCollectionRow: View {
  let subjectId: UInt

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  @Query
  private var collections: [UserSubjectCollection]
  private var collection: UserSubjectCollection? { collections.first }

  init(subjectId: UInt) {
    self.subjectId = subjectId

    _subjects = Query(filter: #Predicate<Subject> {
      $0.id == subjectId
    })
    _collections = Query(filter: #Predicate<UserSubjectCollection> {
      $0.subjectId == subjectId
    })
  }

  var epsColor: Color {
    guard let collection = collection else { return .secondary }
    return collection.epStatus == 0 ? .secondary : .accent
  }

  var volsColor: Color {
    guard let collection = collection else { return .secondary }
    return collection.volStatus == 0 ? .secondary : .accent
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
          if let collection = collection {
            HStack(alignment: .bottom) {
              Text(collection.updatedAt.formatCollectionDate).foregroundStyle(.secondary)
              if collection.priv {
                Image(systemName: "lock.fill").foregroundStyle(.accent)
              }
              Spacer()
              switch collection.subjectTypeEnum {
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
                  collection.subjectTypeEnum.description,
                  systemImage: collection.subjectTypeEnum.icon
                )
                .foregroundStyle(.accent)
              }
            }.font(.caption)
          }
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
      UserCollectionRow(subjectId: subject.id)
        .environmentObject(Notifier())
    }
  }
  .padding()
  .modelContainer(container)
}
