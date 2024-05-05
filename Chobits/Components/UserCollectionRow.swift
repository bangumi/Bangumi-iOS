//
//  UserCollectionRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftData
import SwiftUI

struct UserCollectionRow: View {
  let collection: UserSubjectCollection

  @Query
  private var subjects: [Subject]
  var subject: Subject? { subjects.first }

  init(collection: UserSubjectCollection) {
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
      return "\(collection.epStatus) / \(subject.eps) 话"
    } else {
      return "\(collection.epStatus) / ? 话"
    }
  }

  var volumes: String {
    guard let subject = subject else { return "" }
    if subject.volumes > 0 {
      return "\(collection.volStatus) / \(subject.volumes) 卷"
    } else {
      return "\(collection.volStatus) / ? 卷"
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
      HStack {
        ImageView(img: subject?.images.common, width: 60, height: 60)
        VStack(alignment: .leading) {
          Text(subject?.name ?? "").font(.headline)
          Text(subject?.nameCn ?? "").font(.footnote).foregroundStyle(.secondary)
          HStack {
            Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
            if collection.priv {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            Spacer()
            switch collection.subjectTypeEnum {
            case .anime:
              Text(chapters)
                .foregroundStyle(epsColor)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(epsColor, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }
                .padding(.horizontal, 2)
            case .book:
              Text("\(chapters)")
                .foregroundStyle(epsColor)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(epsColor, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }
                .padding(.horizontal, 4)
              Text("\(volumes)")
                .foregroundStyle(volsColor)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(volsColor, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }
                .padding(.horizontal, 2)
            case .real:
              Text(chapters)
                .foregroundStyle(epsColor)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(epsColor, lineWidth: 1)
                    .padding(.horizontal, -4)
                    .padding(.vertical, -2)
                }
                .padding(.horizontal, 2)
            default:
              Label(
                collection.subjectTypeEnum.description,
                systemImage: collection.subjectTypeEnum.icon
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
  let container = try! ModelContainer(for:Subject.self, UserSubjectCollection.self, configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewBook)
  container.mainContext.insert(Subject.previewBook)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      UserCollectionRow(collection: .previewBook)
        .environmentObject(Notifier())
    }
  }
  .padding()
  .modelContainer(container)
}
