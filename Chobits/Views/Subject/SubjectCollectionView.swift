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

  @State private var refreshed: Bool = false
  @State private var edit: Bool = false

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadUserSubjectCollection(subject.subjectId)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  var body: some View {
    Section {
      VStack(alignment: .leading) {
        if subject.typeEnum == .book && subject.userCollection != nil {
          SubjectBookChaptersView(subjectId: subject.subjectId, compact: false)
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
        .padding(5)
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
      }.task(refresh)
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
