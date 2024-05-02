//
//  UserCollectionRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct UserCollectionRow: View {
  var collection: UserSubjectCollection

  var epsColor: Color {
    collection.epStatus == 0 ? .secondary : .accent
  }

  var volsColor: Color {
    collection.volStatus == 0 ? .secondary : .accent
  }

  var body: some View {
    if let subject = collection.subject {
      let chapters =
        if subject.eps > 0 {
          "\(collection.epStatus) / \(subject.eps) 话"
        } else {
          "\(collection.epStatus) / ? 话"
        }
      let volumes =
        if subject.volumes > 0 {
          "\(collection.volStatus) / \(subject.volumes) 卷"
        } else {
          "\(collection.volStatus) / ? 卷"
        }
      ZStack {
        Rectangle()
          .fill(.accent)
          .opacity(0.01)
          .frame(height: 64)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .shadow(color: .accent, radius: 1, x: 1, y: 1)
        HStack {
          ImageView(img: subject.images.common, width: 60, height: 60)
          VStack(alignment: .leading) {
            Text(subject.name).font(.headline)
            Text(subject.nameCn).font(.footnote).foregroundStyle(.secondary)
            HStack {
              Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
              if collection.private {
                Image(systemName: "lock.fill").foregroundStyle(.accent)
              }
              Spacer()
              switch collection.subjectType {
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
                Label(collection.subjectType.description, systemImage: collection.subjectType.icon)
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
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 10) {
      UserCollectionRow(collection: .previewAnime)
    }
  }.padding()
}
