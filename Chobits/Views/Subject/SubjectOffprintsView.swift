//
//  SubjectOffprintsView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/16.
//

import Foundation
import SwiftData
import SwiftUI

struct SubjectOffprintsView: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @Environment(\.modelContext) var modelContext

  @State private var collections: [Int: CollectionType] = [:]

  func load() {
    Task {
      do {
        let relationIDs = offprints.map { $0.subject.id }
        let collectionDescriptor = FetchDescriptor<UserSubjectCollection>(
          predicate: #Predicate<UserSubjectCollection> {
            relationIDs.contains($0.subjectId)
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
    let _ = Self._printChanges()
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("单行本")
          .foregroundStyle(offprints.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
      }
      Divider()
    }.padding(.top, 5)
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack {
        ForEach(offprints) { offprint in
          NavigationLink(value: NavDestination.subject(offprint.subject.id)) {
            VStack {
              ImageView(
                img: offprint.subject.images?.common,
                width: 60, height: 80, type: .subject
              ) {
              } caption: {
                if let ctype = collections[offprint.subject.id] {
                  HStack {
                    Image(systemName: ctype.icon)
                    Spacer()
                    Text(ctype.description(offprint.subject.type))
                  }.padding(.horizontal, 4)
                }
              }
              Spacer()
            }
            .font(.caption)
            .frame(width: 60, height: 90)
          }.buttonStyle(.navLink)
        }
      }
    }.animation(.default, value: offprints)
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectOffprintsView(
        subjectId: Subject.previewBook.subjectId, offprints: Subject.previewOffprints
      ).modelContainer(mockContainer())
    }.padding()
  }
}
