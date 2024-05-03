//
//  UserCollectionRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct UserCollectionRow: View {
  let collection: UserSubjectCollection

  var epsColor: Color {
    collection.epStatus == 0 ? .secondary : .accent
  }

  var volsColor: Color {
    collection.volStatus == 0 ? .secondary : .accent
  }

  var chapters: String {
    if collection.subject.eps > 0 {
      return "\(collection.epStatus) / \(collection.subject.eps) 话"
    } else {
      return "\(collection.epStatus) / ? 话"
    }
  }

  var volumes: String {
    if collection.subject.volumes > 0 {
      return "\(collection.volStatus) / \(collection.subject.volumes) 卷"
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
        ImageView(img: collection.subject.images.common, width: 60, height: 60)
        VStack(alignment: .leading) {
          Text(collection.subject.name).font(.headline)
          Text(collection.subject.nameCn).font(.footnote).foregroundStyle(.secondary)
          HStack {
            Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
            if collection.private {
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
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 10) {
      UserCollectionRow(collection: .previewAnime)
    }
  }.padding()
}
