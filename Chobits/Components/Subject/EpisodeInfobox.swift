//
//  EpisodeInfobox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import SwiftUI

struct EpisodeInfobox: View {
  let episode: Episode

  var epNumber: String {
    if let ep = episode.ep {
      return ep.episodeDisplay
    } else {
      return episode.sort.episodeDisplay
    }
  }

  var body: some View {
    ScrollView{
      VStack(alignment: .leading) {
        HStack {
          switch episode.typeEnum {
          case .main:
            Text("ep.\(epNumber) \(episode.name)").font(.headline).lineLimit(1)
          case .sp:
            Text("sp.\(episode.sort.episodeDisplay) \(episode.name)").font(.headline)
          case .op:
            Text("op.\(episode.sort.episodeDisplay) \(episode.name)").font(.headline)
          case .ed:
            Text("ed.\(episode.sort.episodeDisplay) \(episode.name)").font(.headline)
          }
          Text(episode.typeEnum.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .overlay {
              RoundedRectangle(cornerRadius: 5)
                .stroke(Color.secondary, lineWidth: 1)
                .padding(.horizontal, -4)
                .padding(.vertical, -2)
            }
          Spacer()
          if episode.comment > 0 {
            Label("讨论", systemImage: "bubble.fill").font(.caption).foregroundStyle(.secondary)
            Text("(+\(episode.comment))").font(.caption).foregroundStyle(.red)
          }
        }
        Divider()
        if !episode.name.isEmpty {
          Text("标题: \(episode.name)")
        }
        if !episode.nameCn.isEmpty {
          Text("中文标题: \(episode.nameCn)")
        }
        if !episode.airdate.isEmpty {
          Text("首播时间: \(episode.airdate)")
        }
        if !episode.duration.isEmpty {
          Text("时长: \(episode.duration)")
        }
        if episode.disc > 0 {
          Text("Disc: \(episode.disc)")
        }
        if !episode.desc.isEmpty {
          Text("描述:")
          Text(episode.desc).foregroundStyle(.secondary)
        }
        Spacer()
      }
    }.padding()
  }
}

#Preview {
  EpisodeInfobox(episode: Episode.preview)
}
