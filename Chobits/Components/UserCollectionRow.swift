//
//  UserCollectionRow.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct UserCollectionRow: View {
  var collection: UserSubjectCollection

  var body: some View {
    if let subject = collection.subject {
      let chapters = if subject.eps > 0 {
        "\(collection.epStatus)/\(subject.eps) 话"
      } else {
        "\(collection.epStatus)/? 话"
      }
      let volumes = if subject.volumes > 0 {
        "\(collection.volStatus)/\(subject.volumes) 卷"
      } else {
        "\(collection.volStatus)/? 卷"
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
            switch collection.subjectType {
            case .anime:
              HStack {
                Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
                Spacer()
                Text(chapters).foregroundStyle(.accent)
              }.font(.caption)
            case .book:
              HStack {
                Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
                Spacer()
                Text("\(chapters)  \(volumes)").foregroundStyle(.accent)
              }.font(.caption)
            case .real:
              HStack {
                Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
                Spacer()
                Text(chapters).foregroundStyle(.accent)
              }.font(.caption)
            default:
              HStack {
                Text(collection.updatedAt.formatted()).foregroundStyle(.secondary)
                Spacer()
                Label(collection.subjectType.description, systemImage: collection.subjectType.icon).foregroundStyle(.accent)
              }.font(.caption)
            }
          }
          Spacer()
        }
        .frame(height: 60)
        .padding(2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
    } else {
      EmptyView()
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading, spacing: 10) {
      UserCollectionRow(collection: .preview)
    }
  }.padding()
}
