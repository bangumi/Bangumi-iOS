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

  @State private var subject: Subject? = nil
  @State private var summaryCollapsed = true

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
          if chiiClient.isAuthenticated {
            SubjectCollectionView(subject: subject)
          }
          if !subject.summary.isEmpty {
            SubjectSummaryView(subject: subject)
          }
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

  @State private var coverDetail = false
  @State private var collectionDetail = false

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: subject.images.common, width: 100, height: 150)
        .onTapGesture {
          coverDetail.toggle()
        }
        .sheet(isPresented: $coverDetail) {
          ImageView(img: subject.images.large, width: 0, height: 0)
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.8)])
        }
      VStack(alignment: .leading) {
        HStack {
          Text(subject.platform).foregroundStyle(.secondary)
          Label(subject.type.description, systemImage: subject.type.icon).foregroundStyle(.accent)
          if let date = subject.date {
            Label(date, systemImage: "calendar").foregroundStyle(.secondary)
          }
          Spacer()
          if subject.nsfw {
            Label("", systemImage: "18.circle").foregroundStyle(.red)
          }
          if subject.locked {
            Label("", systemImage: "lock").foregroundStyle(.red)
          }
        }.font(.caption)
        Spacer()
        Text(subject.name)
          .font(.headline)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        Spacer()
        Text(subject.nameCn)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        Spacer()
        HStack {
          Label("\(subject.rating.total)", systemImage: "bookmark")
          if subject.rating.rank > 0 {
            Label("\(subject.rating.rank)", systemImage: "chart.bar.xaxis")
          }
          if subject.rating.score > 0 {
            let score = String(format: "%.1f", subject.rating.score)
            Label("\(score)", systemImage: "star")
          }
          Spacer()
        }
        .font(.caption)
        .foregroundStyle(.accent)
        .onTapGesture {
          collectionDetail.toggle()
        }
        .sheet(isPresented: $collectionDetail, content: {
          SubjectRatingView(subject: subject)
            .presentationDetents(.init([.medium]))
        })
      }
    }
  }
}

struct SubjectRatingView: View {
  var subject: Subject

  var collectionDesc: String {
    var text = ""
    if let wish = subject.collection.wish {
      text += "\(wish) 人\(CollectionType.wish.description(type: subject.type))"
      text += " / "
    }
    if let collect = subject.collection.collect {
      text += "\(collect) 人\(CollectionType.collect.description(type: subject.type))"
      text += " / "
    }
    if let doing = subject.collection.doing {
      text += "\(doing) 人\(CollectionType.do.description(type: subject.type))"
      text += " / "
    }
    if let onHold = subject.collection.onHold {
      text += "\(onHold) 人\(CollectionType.onHold.description(type: subject.type))"
      text += " / "
    }
    if let dropped = subject.collection.dropped {
      text += "\(dropped) 人\(CollectionType.dropped.description(type: subject.type))"
    }
    return text
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("\(subject.rating.total) 人评分")
      Text(collectionDesc)
      if subject.rating.rank > 0 {
        Text("Bangumi 排名 \(subject.rating.rank)")
      }
      if subject.rating.score > 0 {
        let score = String(format: "%.1f", subject.rating.score)
        Text("评分 \(score)")
      }
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
      let tags = subject.tags.sorted { $0.count > $1.count }.prefix(20)
      Text("标签").font(.headline)
      FlowStack {
        ForEach(tags, id: \.name) { tag in
          HStack {
            Text(tag.name)
              .font(.caption)
              .foregroundColor(.accent)
              .lineLimit(1)
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
