//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectCollectionView: View {
  var subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var empty: Bool = false
  @State private var collection: UserSubjectCollection?

  func fetchCollection() {
    Task.detached {
      do {
        let collection = try await chii.getCollection(sid: subject.id)
        await MainActor.run {
          self.collection = collection
          self.empty = false
        }
      } catch ChiiError.notFound(_) {
        await MainActor.run {
          self.empty = true
        }
      } catch {
        await notifier.alert(message: "\(error)")
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack{
        Text("收藏").font(.headline)
        Spacer()
        if let collection = collection {
          Text(collection.type.message(type: collection.subjectType))
            .font(.footnote)
            .foregroundStyle(Color("LinkTextColor"))
            .overlay {
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color("LinkBorderColor"), lineWidth: 1)
                .padding(.horizontal, -4)
                .padding(.vertical, -2)
            }
            .padding(5)
        } else {
          if empty {
            Text("未收藏")
              .font(.footnote)
              .foregroundStyle(.secondary)
              .overlay {
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.secondary, lineWidth: 1)
                  .padding(.horizontal, -4)
                  .padding(.vertical, -2)
              }
              .padding(5)
          }
        }
      }
      HStack{
        if let collection = collection {
          // TODO: show
          Text("\(collection.updatedAt)").font(.caption)
        } else {
          if empty {
            // TODO: show
            EmptyView()
          } else {
            Spacer()
            ProgressView().onAppear(perform: fetchCollection)
            Spacer()
          }
        }
      }
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subject: .preview)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: true))
    }
  }.padding()
}
