//
//  SubjectRecsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/3.
//

import Foundation
import SwiftData
import SwiftUI

struct SubjectRecsView: View {
  let subjectId: Int
  let recs: [SubjectRecDTO]

  @Environment(\.modelContext) var modelContext

  @State private var collections: [Int: CollectionType] = [:]

  func load() {
    Task {
      do {
        let recIDs = recs.map { $0.subject.id }
        let collectionDescriptor = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            recIDs.contains($0.subjectId)
          })
        let collects = try modelContext.fetch(collectionDescriptor)
        for collection in collects {
          self.collections[collection.subjectId] = collection.typeEnum
        }
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("猜你喜欢")
          .foregroundStyle(recs.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: load)
        Spacer()
      }
      Divider()
    }.padding(.top, 5)
    if recs.count == 0 {
      HStack {
        Spacer()
        Text("暂无推荐")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack {
        ForEach(recs) { rec in
          VStack {
            NavigationLink(value: NavDestination.subject(rec.subject.id)) {
              ImageView(
                img: rec.subject.images?.common,
                width: 72, height: 96, type: .subject
              ) {
              } caption: {
                if let ctype = collections[rec.subject.id] {
                  HStack {
                    Image(systemName: ctype.icon)
                    Spacer()
                    Text(ctype.description(rec.subject.type))
                  }.padding(.horizontal, 4)
                }
              }
            }.buttonStyle(.navLink)
            Text(rec.subject.name)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
            Spacer()
          }
          .font(.caption)
          .frame(width: 72, height: 140)
        }
      }
    }.animation(.default, value: recs)
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRecsView(
        subjectId: Subject.previewAnime.subjectId, recs: Subject.previewRecs
      ).modelContainer(mockContainer())
    }.padding()
  }
}
