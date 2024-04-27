//
//  SubjectView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  var sid: UInt

  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var errorHandling: ErrorHandling

  @Query private var collections: [UserSubjectCollection]
  var collection: UserSubjectCollection? { collections.first }

  @State private var subject: Subject? = nil

  init(sid: UInt) {
    self.sid = sid
    _collections = Query(filter: #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == sid
    })
  }

  func fetchSubject() {
    Task.detached {
      do {
        let subject = try await chiiClient.getSubject(sid: sid)
        await MainActor.run {
          withAnimation {
            self.subject = subject
          }
        }
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    if let subject = subject {
      ScrollView {
        LazyVStack {
          Text(subject.nameCn)
            .font(.caption)
            .foregroundStyle(.gray)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          Text(subject.name)
            .font(.title3)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
        }
      }
    } else {
      Image(systemName: "waveform")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        .onAppear(perform: fetchSubject)
    }

//    if let collection = collection {
//      Text("\(collection.updatedAt)")
//    } else {
//      EmptyView().onAppear()
//    }
    //    VStack(alignment: .leading) {
    //      HStack(alignment: .top) {
    //        ImageView(img: subject.images.common, size: 100)
    //        VStack(alignment: .leading) {
    //
    //          Text(subject.name).font(.headline).multilineTextAlignment(.leading)
    //            .lineLimit(2)
    //          Label(subject.type.description(), systemImage: subject.type.icon).font(.subheadline).foregroundStyle(.accent)
    //        }
    //        Spacer()
    //      }
    //      Text("简介").font(.headline)
    //      Text(subject.shortSummary).font(.caption).multilineTextAlignment(.leading)
    //      Spacer()
    //    }.padding([.horizontal], 10).padding([.vertical], 20)
    //  }

    Text("Hello, Subject: \(sid)")
  }
}
