//
//  SubjectHeaderView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftData
import SwiftUI

struct SubjectHeaderView: View {
  @ObservableModel var subject: Subject

  @State private var collectionDetail = false

  var scoreDescription: String {
    let score = Int(subject.rating.score.rounded())
    return score.ratingDescription
  }

  var nameCN: String {
    if subject.nameCN.isEmpty {
      return subject.name
    }
    return subject.nameCN
  }

  var body: some View {
    if subject.locked {
      ZStack {
        HStack {
          Image("Musume")
            .scaleEffect(x: 0.5, y: 0.5, anchor: .bottomLeading)
            .offset(x: -40, y: 20)
            .frame(width: 36, height: 60, alignment: .bottomLeading)
            .clipped()
            .padding(.horizontal, 5)
          VStack(alignment: .leading) {
            Text("条目已锁定")
              .font(.callout.bold())
              .foregroundStyle(.accent)
            Text("同人誌，条目及相关收藏、讨论、关联等内容将会随时被移除。")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Spacer()
        }
        RoundedRectangle(cornerRadius: 5)
          .stroke(.accent, lineWidth: 1)
          .padding(.horizontal, 1)
      }
    }
    Text(subject.name)
      .font(.title2.bold())
      .multilineTextAlignment(.leading)
      .textSelection(.enabled)
    HStack {
      if subject.nsfw {
        ImageView(
          img: subject.images?.common, width: 120, height: 160, type: .subject, overlay: .badge
        ) {
          Text("18+")
            .padding(2)
            .background(.red.opacity(0.8))
            .padding(2)
            .foregroundStyle(.white)
            .font(.caption)
            .clipShape(Capsule())
        }
      } else {
        ImageView(img: subject.images?.common, width: 120, height: 160, type: .subject)
      }
      VStack(alignment: .leading) {
        HStack {
          if subject.typeEnum != .none {
            Label(subject.category, systemImage: subject.typeEnum.icon)
          }
          if subject.airtime.date != "" {
            Label(subject.airtime.date, systemImage: "calendar")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        Spacer()
        Text(nameCN)
          .multilineTextAlignment(.leading)
          .truncationMode(.middle)
          .lineLimit(2)
          .textSelection(.enabled)
        Spacer()

        NavigationLink(value: NavDestination.subjectInfobox(subject: subject)) {
          HStack {
            Text(subject.info)
              .font(.caption)
              .lineLimit(2)
            Spacer()
            Image(systemName: "chevron.right")
          }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.linkText)

        Spacer()
        HStack {
          Text(
            "\(subject.collection.doing) 人\(CollectionType.do.description(subject.typeEnum))"
          )
          Text("/")
          Text(
            "\(subject.collection.collect) 人\(CollectionType.collect.description(subject.typeEnum))"
          )
          Spacer()
        }
        .font(.footnote)
        .foregroundStyle(.secondary)

        if subject.rating.total > 10 {
          HStack {
            if subject.rating.score > 0 {
              StarsView(score: Float(subject.rating.score), size: 12)
              Text("\(subject.rating.score.rateDisplay)")
                .foregroundStyle(.orange)
                .font(.callout)
              Text("(\(subject.rating.total) 人评分)")
                .foregroundStyle(.linkText)
              Spacer()
            }
          }
          .font(.footnote)
          .onTapGesture {
            collectionDetail.toggle()
          }
          .sheet(
            isPresented: $collectionDetail,
            content: {
              SubjectRatingBoxView(subject: subject)
            }
          )
        } else {
          HStack {
            StarsView(score: 0, size: 12)
            Text("(少于 10 人评分)")
              .foregroundStyle(.secondary)
          }
          .font(.footnote)
        }
      }
    }

    if subject.rating.rank > 0 && subject.rating.rank < 1000 {
      BorderView(color: .accent, padding: 5) {
        HStack {
          Spacer()
          Label(
            "Bangumi \(subject.typeEnum.name.capitalized) Ranked:",
            systemImage: "chart.bar.xaxis"
          )
          Text("#\(subject.rating.rank)")
          Spacer()
        }
        .font(.callout)
        .foregroundStyle(.accent)
      }.padding(5)
    }
  }
}

#Preview {
  let container = mockContainer()

  @Bindable var subject = Subject.previewBook
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectHeaderView(subject: subject)
        .modelContainer(container)
    }
  }.padding()
}
