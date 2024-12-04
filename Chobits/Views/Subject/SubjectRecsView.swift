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

  @State private var loaded: Bool = false
  @State private var loading: Bool = false
  @State private var recs: [SubjectRecDTO] = []

  func load() {
    if loading || loaded {
      return
    }
    loading = true
    Task {
      do {
        let resp = try await Chii.shared.getSubjectRecs(subjectId, limit: 10)
        recs.append(contentsOf: resp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    Divider()
    HStack {
      Text("猜你喜欢")
        .foregroundStyle(recs.count > 0 ? .primary : .secondary)
        .font(.title3)
        .onAppear(perform: load)
      if loading {
        ProgressView()
      }
      Spacer()
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack {
        ForEach(recs) { rec in
          NavigationLink(value: NavDestination.subject(subjectId: rec.subject.id)) {
            VStack {
              ImageView(
                img: rec.subject.images?.common, width: 72, height: 96, type: .subject)
              Text(rec.subject.name)
                .multilineTextAlignment(.leading)
                .truncationMode(.middle)
                .lineLimit(2)
              Spacer()
            }
            .font(.caption)
            .frame(width: 72, height: 140)
          }.buttonStyle(.plain)
        }
      }
    }.animation(.default, value: recs)
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectRecsView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
