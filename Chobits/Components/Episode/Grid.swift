//
//  EpisodeCollection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import OSLog
import SwiftData
import SwiftUI

struct EpisodeGridView: View {
  let subjectId: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var selected: Episode? = nil
  @StateObject private var page: PageStatus = PageStatus()

  @Query private var mains: [Episode]
  @Query private var sps: [Episode]
  @Query private var ops: [Episode]
  @Query private var eds: [Episode]

  init(subjectId: UInt) {
    self.subjectId = subjectId

    let mainType = EpisodeType.main.rawValue
    let spType = EpisodeType.sp.rawValue
    let opType = EpisodeType.op.rawValue
    let edType = EpisodeType.ed.rawValue

    var mainDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == mainType
      }, sortBy: [SortDescriptor(\.sort)])
    mainDescriptor.fetchLimit = 50
    _mains = Query(mainDescriptor)

    var spDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == spType
      }, sortBy: [SortDescriptor(\.sort)])
    spDescriptor.fetchLimit = 10
    _sps = Query(spDescriptor)

    var opDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == opType
      }, sortBy: [SortDescriptor(\.sort)])
    opDescriptor.fetchLimit = 10
    _ops = Query(opDescriptor)

    var edDescriptor = FetchDescriptor<Episode>(
      predicate: #Predicate<Episode> {
        $0.subjectId == subjectId && $0.type == edType
      }, sortBy: [SortDescriptor(\.sort)])
    edDescriptor.fetchLimit = 10
    _eds = Query(edDescriptor)
  }

  func update(authenticated: Bool) async {
    if !self.page.start() {
      return
    }
    let actor = BackgroundActor(container: modelContext.container)
    do {
      var offset: Int = 0
      let limit: Int = 1000
      let subjectId = subjectId
      while true {
        var total: Int = 0
        if authenticated {
          let response = try await chii.getEpisodeCollections(
            subjectId: subjectId, type: nil, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for item in response.data {
            let episode = Episode(collection: item, subjectId: subjectId)
            await actor.insert(data: episode)
          }
          total = response.total
        } else {
          let response = try await chii.getSubjectEpisodes(
            subjectId: subjectId, type: nil, limit: limit, offset: offset)
          if response.data.isEmpty {
            break
          }
          for item in response.data {
            let episode = Episode(item: item, subjectId: subjectId)
            await actor.insert(data: episode)
          }
          total = response.total
        }
        offset += limit
        if offset > total {
          break
        }
      }
      try await actor.save()
      await MainActor.run {
        page.success()
      }
    } catch {
      await MainActor.run {
        notifier.alert(error: error)
        page.finish()
      }
    }
  }

  var body: some View {
    HStack {
      if chii.isAuthenticated {
        Text("观看进度管理:")
      } else {
        Text("章节列表:")
      }
      NavigationLink(value: NavEpisodeList(subjectId: subjectId)) {
        Text("[全部]").foregroundStyle(Color("LinkTextColor"))
      }.buttonStyle(.plain)
      Spacer()
    }
    .font(.callout)
    .task(priority: .background) {
      await update(authenticated: chii.isAuthenticated)
    }
    FlowStack {
      ForEach(mains) { episode in
        Button {
          selected = episode
        } label: {
          Text("\(episode.sort.episodeDisplay)")
            .foregroundStyle(Color(hex: episode.textColor))
            .font(.callout)
            .padding(3)
            .background(Color(hex: episode.backgroundColor))
            .border(Color(hex: episode.borderColor), width: 1)
            .padding(2)
            .monospaced()
            .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
        }
      }
      if !sps.isEmpty {
        Text("SP")
          .foregroundStyle(Color(hex: 0x8EB021))
          .font(.callout)
          .padding(.vertical, 3)
          .padding(.leading, 5)
          .padding(.trailing, 1)
          .overlay(
            Rectangle()
              .frame(width: 3)
              .foregroundColor(Color(hex: 0x8EB021))
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
          .monospaced()
        ForEach(sps) { episode in
          Button {
            selected = episode
          } label: {
            Text("\(episode.sort.episodeDisplay)")
              .foregroundStyle(Color(hex: episode.textColor))
              .font(.callout)
              .padding(3)
              .background(Color(hex: episode.backgroundColor))
              .border(Color(hex: episode.borderColor), width: 1)
              .padding(2)
              .monospaced()
              .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
          }
        }
      }
      if !ops.isEmpty {
        Text("OP")
          .foregroundStyle(Color(hex: 0x8EB021))
          .font(.callout)
          .padding(.vertical, 3)
          .padding(.leading, 5)
          .padding(.trailing, 1)
          .overlay(
            Rectangle()
              .frame(width: 3)
              .foregroundColor(Color(hex: 0x8EB021))
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
          .monospaced()
        ForEach(ops) { episode in
          Button {
            selected = episode
          } label: {
            Text("\(episode.sort.episodeDisplay)")
              .foregroundStyle(Color(hex: episode.textColor))
              .font(.callout)
              .padding(3)
              .background(Color(hex: episode.backgroundColor))
              .border(Color(hex: episode.borderColor), width: 1)
              .padding(2)
              .monospaced()
              .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
          }
        }
      }
      if !eds.isEmpty {
        Text("ED")
          .foregroundStyle(Color(hex: 0x8EB021))
          .font(.callout)
          .padding(.vertical, 3)
          .padding(.leading, 5)
          .padding(.trailing, 1)
          .overlay(
            Rectangle()
              .frame(width: 3)
              .foregroundColor(Color(hex: 0x8EB021))
              .offset(x: -12, y: 0)
          )
          .padding(2)
          .bold()
          .monospaced()
        ForEach(eds) { episode in
          Button {
            selected = episode
          } label: {
            Text("\(episode.sort.episodeDisplay)")
              .foregroundStyle(Color(hex: episode.textColor))
              .font(.callout)
              .padding(3)
              .background(Color(hex: episode.backgroundColor))
              .border(Color(hex: episode.borderColor), width: 1)
              .padding(2)
              .monospaced()
              .strikethrough(episode.collection == EpisodeCollectionType.dropped.rawValue)
          }
        }
      }
    }
    .animation(.default, value: mains)
    .animation(.default, value: sps)
    .animation(.default, value: ops)
    .animation(.default, value: eds)
    .animation(.default, value: selected)
    .sheet(
      item: $selected,
      content: { episode in
        EpisodeInfobox(episode: episode)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      }
    )
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self,
    configurations: config)
  container.mainContext.insert(UserSubjectCollection.previewAnime)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      EpisodeGridView(subjectId: Subject.previewAnime.id)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .anime))
    }
  }
  .padding()
  .modelContainer(container)
}
