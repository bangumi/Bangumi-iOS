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
  @State private var summaryCollapsed = true

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
        LazyVStack(alignment: .leading) {
          SubjectHeaderView(subject: subject)
          SubjectCollectionView(subject: subject)
          SubjectSummaryView(subject: subject)
          SubjectTagView(subject: subject)
          Spacer()
        }
      }
      .padding()
    } else {
      Image(systemName: "waveform")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        .onAppear(perform: fetchSubject)
    }
  }
}

struct SubjectHeaderView: View {
  var subject: Subject

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: subject.images.common, size: 100)
      VStack(alignment: .leading) {
        HStack {
          Label(subject.type.description, systemImage: subject.type.icon).foregroundStyle(.accent)
          if let date = subject.date {
            Label(date, systemImage: "calendar").foregroundStyle(.secondary)
          }
          Spacer()
        }.font(.caption)
        Text(subject.nameCn)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        Text(subject.name)
          .font(.headline)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        HStack {
          Text("\(subject.rating.total) 人收藏").foregroundStyle(.secondary)
          if subject.rating.rank > 0 {
            Label("\(subject.rating.rank)", systemImage: "chart.bar.xaxis").foregroundStyle(.accent)
          }
          if subject.rating.score > 0 {
            let score = String(format: "%.1f", subject.rating.score)
            Label("\(score)", systemImage: "star").foregroundStyle(.accent)
          }
          Spacer()
        }.font(.caption)
      }
      Spacer()
    }
  }
}

struct SubjectCollectionView: View {
  var subject: Subject

  var body: some View {
    VStack(alignment: .leading) {
      Text("收藏").font(.headline)
    }.padding(.vertical, 10)
  }
}

struct SubjectSummaryView: View {
  var subject: Subject

  @State private var collapsed = true

  var body: some View {
    VStack(alignment: .leading) {
      Text("简介").font(.headline)
      Text(subject.summary)
        .font(.caption)
        .multilineTextAlignment(.leading)
        .lineLimit(collapsed ? 5 : nil)
      HStack {
        Spacer()
        Button {
          withAnimation {
            collapsed.toggle()
          }
        } label: {
          if collapsed {
            Text("more")
          } else {
            Text("close")
          }
        }
        .buttonStyle(PlainButtonStyle())
        .font(.caption)
        .foregroundStyle(.accent)
      }
    }.padding(.vertical, 10)
  }
}

struct SubjectTagView: View {
  var subject: Subject

  var body: some View {
    VStack(alignment: .leading) {
      Text("标签").font(.headline)
      FlowStack {
        ForEach(subject.tags, id: \.name) { tag in
          HStack {
            Text(tag.name)
              .font(.caption)
              .foregroundColor(.accent)
            Text("\(tag.count)")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          .padding(.horizontal, 6)
          .padding(.vertical, 4)
          .overlay {
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color.secondary, lineWidth: 1)
              .padding(.horizontal, 2)
              .padding(.vertical, 2)
          }
        }
      }
    }.padding(.vertical, 10)
  }
}
