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

  init(sid: UInt) {
    self.sid = sid
    _collections = Query(filter: #Predicate<UserSubjectCollection> { collection in
      collection.subjectId == sid
    })
  }

  var body: some View {
    //    if let collection = collection {
    //    } else {
    //      EmptyView().onAppear()
    //    }
    //    VStack(alignment: .leading) {
    //      HStack(alignment: .top) {
    //        ImageView(img: subject.images.common, size: 100)
    //        VStack(alignment: .leading) {
    //          Text(subject.nameCn).font(.caption).foregroundStyle(.gray).multilineTextAlignment(.leading)
    //            .lineLimit(2)
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
