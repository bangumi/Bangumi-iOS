//
//  ListCollection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/5.
//

import SwiftData
import SwiftUI

struct EpisodeListCollectionView: View {
  let subject: Subject

  @EnvironmentObject var notifier: Notifier
  @Environment(\.modelContext) var modelContext

  @State private var now: Date = Date()
  @State private var offset: Int = 0
  @State private var type: EpisodeType = .main
  @State private var sortDesc: Bool = false
  @State private var exhausted: Bool = false
  @State private var selected: EpisodeCollection? = nil
  @State private var collections: [EpisodeCollection] = []

  func fetch(limit: Int = 50) async -> [EpisodeCollection] {
    let actor = BackgroundActor(container: modelContext.container)
    let sortBy =
      sortDesc
      ? SortDescriptor<EpisodeCollection>(\.sort, order: .reverse)
      : SortDescriptor<EpisodeCollection>(\.sort)
    var descriptor = FetchDescriptor<EpisodeCollection>(
      predicate: #Predicate {
        $0.subjectId == subject.id && $0.episodeType == type.rawValue
      }, sortBy: [sortBy])
    descriptor.fetchLimit = limit
    descriptor.fetchOffset = offset
    do {
      let collections = try await actor.fetchData(descriptor: descriptor)
      if collections.count < limit {
        exhausted = true
      }
      offset += limit
      return collections
    } catch {
      notifier.alert(error: error)
    }
    return []
  }

  func load() async {
    offset = 0
    exhausted = false
    collections.removeAll()
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
  }

  func loadNextPage(current: EpisodeCollection) async {
    if exhausted {
      return
    }
    let thresholdIndex = collections.index(collections.endIndex, offsetBy: -2)
    let currentIndex = collections.firstIndex(where: { $0.id == current.id })
    if currentIndex != thresholdIndex {
      return
    }
    let collections = await fetch()
    self.collections.append(contentsOf: collections)
  }

  var body: some View {
    HStack {
      Picker("Episode Type", selection: $type) {
        ForEach(EpisodeType.allTypes()) { et in
          Text("\(et.description)").tag(et)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: type) {
        Task {
          await load()
        }
      }
      Spacer()
      Toggle(isOn: $sortDesc) {
      }
      .frame(width: 50)
      .toggleStyle(.switch)
      .onChange(of: sortDesc) {
        Task {
          await load()
        }
      }
    }.padding(.horizontal, 16)
    ScrollView {
      LazyVStack {
        EmptyView()
        ForEach(collections) { collection in
          Button {
            selected = collection
          } label: {
            VStack(alignment: .leading) {
              Text(collection.episode.title)
                .font(.headline)
                .lineLimit(1)
              HStack {
                if collection.airdate > now {
                  Text("未播")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .overlay {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary, lineWidth: 1)
                        .padding(.horizontal, -4)
                        .padding(.vertical, -2)
                    }
                    .padding(.horizontal, 10)
                } else {
                  Text("已播")
                    .font(.callout)
                    .overlay {
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.secondary, lineWidth: 1)
                        .padding(.horizontal, -4)
                        .padding(.vertical, -2)
                    }
                    .padding(.horizontal, 10)
                }
                VStack(alignment: .leading) {
                  Text(collection.episode.nameCn)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                  Text(
                    "时长:\(collection.episode.duration) / 首播:\(collection.episode.airdate) / 讨论:+\(collection.episode.comment)"
                  )
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                }
                Spacer()
              }
            }
            .padding(5)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .buttonStyle(.plain)
    .animation(.default, value: collections)
    .task {
      await load()
    }
    .sheet(
      item: $selected,
      content: { collection in
        EpisodeInfobox(collection: collection)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      })
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(
    for: UserSubjectCollection.self, Subject.self, Episode.self, EpisodeCollection.self,
    configurations: config)
  let collections = EpisodeCollection.previewList
  for collection in collections {
    container.mainContext.insert(collection)
  }

  return EpisodeListCollectionView(subject: .previewAnime)
    .environmentObject(Notifier())
    .modelContainer(container)
}
