//
//  CharacterView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import OSLog
import SwiftData
import SwiftUI

struct CharacterView: View {
  var characterId: Int

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var refreshed: Bool = false
  @State private var showSummary: Bool = false
  @State private var showInfobox: Bool = false

  @Query private var characters: [Character]
  private var character: Character? { characters.first }

  init(characterId: Int) {
    self.characterId = characterId
    let predicate = #Predicate<Character> {
      $0.characterId == characterId
    }
    _characters = Query(filter: predicate, sort: \Character.characterId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/character/\(characterId)")!
  }

  var nameCN: String {
    guard let character = character else {
      return ""
    }
    if character.nameCN.isEmpty {
      return character.name
    }
    return character.nameCN
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadCharacter(characterId)
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
    refreshed = true
  }

  func shouldShowToggle(
    _ geometry: GeometryProxy,
    font: UIFont.TextStyle = .body, limits: Int = 5
  )
    -> Bool
  {
    let lines = Int(
      geometry.size.height / UIFont.preferredFont(forTextStyle: font).lineHeight)
    if lines < limits {
      return false
    }
    return true
  }

  var body: some View {
    Section {
      if let character = character {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {

            /// title
            Text(character.name)
              .font(.title2.bold())
              .multilineTextAlignment(.leading)

            /// header
            HStack(alignment: .top) {
              ImageView(img: character.images?.medium, width: 120, height: 160, alignment: .top)
              VStack(alignment: .leading) {
                HStack {
                  Label(character.roleEnum.description, systemImage: character.roleEnum.icon)
                  if character.collects > 0 {
                    Text("(\(character.collects)人收藏)").lineLimit(1)
                  }
                  Spacer()
                  if !isolationMode {
                    Label("评论: \(character.comment)", systemImage: "bubble")
                      .lineLimit(1)
                      .font(.footnote)
                      .foregroundStyle(.linkText)
                  }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
                Text(nameCN)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                  .textSelection(.enabled)
                Spacer()

                VStack(alignment: .leading) {
                  ForEach(character.infobox.header(), id: \.key) { item in
                    HStack(alignment: .top) {
                      Text("\(item.key):").fixedSize(horizontal: false, vertical: true)
                      VStack(alignment: .leading) {
                        ForEach(item.values, id: \.v) { value in
                          HStack {
                            if let k = value.k {
                              Text("\(k):")
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            }
                            Text(value.v)
                              .textSelection(.enabled)
                              .lineLimit(1)
                          }
                        }
                      }
                    }
                  }
                }
                .font(.footnote)
                .frame(maxHeight: 72, alignment: .top)
                .clipped()
                .sheet(isPresented: $showInfobox) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("资料").font(.title3).padding(.vertical, 10)
                      VStack(alignment: .leading) {
                        ForEach(character.infobox, id: \.key) { item in
                          HStack(alignment: .top) {
                            Text("\(item.key):").fixedSize(horizontal: false, vertical: true)
                            VStack(alignment: .leading) {
                              ForEach(item.values, id: \.v) { value in
                                HStack {
                                  if let k = value.k {
                                    Text("\(k):")
                                      .font(.footnote)
                                      .foregroundStyle(.secondary)
                                      .lineLimit(1)
                                  }
                                  Text(value.v)
                                    .textSelection(.enabled)
                                    .lineLimit(1)
                                }
                              }
                            }
                          }
                          Divider()
                        }
                      }
                      .presentationDragIndicator(.visible)
                      Spacer()
                    }.padding()
                  }
                }
                Spacer()
                Button(action: {
                  showInfobox.toggle()
                }) {
                  Text("more...")
                    .font(.caption)
                    .foregroundStyle(.linkText)
                }
              }.padding(.leading, 2)
            }

            /// summary
            Section {
              Text(character.summary)
                .font(.footnote)
                .padding(.bottom, 16)
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .sheet(isPresented: $showSummary) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("简介").font(.title3).padding(.vertical, 10)
                      Text(character.summary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                      Spacer()
                    }.padding()
                  }
                }
                .overlay(
                  GeometryReader { geometry in
                    if shouldShowToggle(geometry, font: .footnote) {
                      Button(action: {
                        showSummary.toggle()
                      }) {
                        Text("more...")
                          .font(.caption)
                          .foregroundStyle(.linkText)
                      }
                      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                  }
                )
            }

            /// casts
            CharacterCastsView(characterId: characterId)
          }.padding(.horizontal, 8)
        }
      } else {
        if refreshed {
          NotFoundView()
        } else {
          ProgressView()
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .navigationTitle(character?.name ?? "角色")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await refresh()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  container.mainContext.insert(character)

  return NavigationStack {
    CharacterView(characterId: character.characterId)
      .modelContainer(container)
  }
}
