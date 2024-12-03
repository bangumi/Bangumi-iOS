//
//  SubjectCollectionView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import OSLog
import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  @ObservableModel var subject: Subject

  @Environment(\.modelContext) var modelContext

  @State private var edit: Bool = false

  var body: some View {
    Section {
      VStack(alignment: .leading) {
        if subject.typeEnum == .book {
          SubjectBookChaptersView(subject: subject, compact: false)
        }
        BorderView(color: .linkText, padding: 5) {
          HStack {
            Spacer()
            if let collection = subject.userCollection {
              if collection.priv {
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
              }
              Label(collection.message, systemImage: collection.typeEnum.icon)
              StarsView(score: Float(collection.rate), size: 16)
            } else {
              Label("未收藏", systemImage: "plus")
                .foregroundStyle(.secondary)
            }
            Spacer()
          }
          .foregroundStyle(.linkText)
        }
        .onTapGesture {
          edit.toggle()
        }
        .sheet(
          isPresented: $edit,
          content: {
            SubjectCollectionBoxView(subject: subject)
              .presentationDragIndicator(.visible)
              .presentationDetents(.init([.medium, .large]))
          })
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  let collection = UserSubjectCollection.previewBook
  container.mainContext.insert(subject)
  container.mainContext.insert(collection)
  collection.subject = subject

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subject: subject)
        .modelContainer(container)
    }
  }
  .padding()
}
