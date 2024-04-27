//
//  CollectionDetailView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct CollectionDetailView: View {
  var collection: UserSubjectCollection

  var body: some View {
    if let subject = collection.subject {
      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          ImageView(img: subject.images.common, size: 100)
          VStack(alignment: .leading) {
            Text(subject.nameCn).font(.caption).foregroundStyle(.gray).multilineTextAlignment(.leading)
              .lineLimit(2)
            Text(subject.name).font(.headline).multilineTextAlignment(.leading)
              .lineLimit(2)
            Label(collection.type.description(type: collection.subjectType), systemImage: collection.type.icon).font(.subheadline).foregroundStyle(.accent)
          }
          Spacer()
        }
        Text("章节").font(.headline)
        Text("简介").font(.headline)
        Text(subject.shortSummary).font(.caption).multilineTextAlignment(.leading)
        Spacer()
      }.padding([.horizontal], 10).padding([.vertical], 20)
    } else {
      EmptyView()
    }
  }
}
