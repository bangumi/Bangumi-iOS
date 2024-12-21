import SwiftData
import SwiftUI

struct SubjectHeaderView: View {
  @Environment(Subject.self) var subject

  var nameCN: String {
    if subject.nameCN.isEmpty {
      return subject.name
    }
    return subject.nameCN
  }

  var type: SubjectType {
    subject.typeEnum
  }

  var body: some View {
    if subject.locked {
      SubjectLockView()
    }
    Text(subject.name)
      .font(.title2.bold())
      .multilineTextAlignment(.leading)
      .textSelection(.enabled)
    HStack {
      ImageView(img: subject.images?.common) {
        if subject.nsfw {
          Text("18+")
            .padding(2)
            .background(.red.opacity(0.8))
            .padding(2)
            .foregroundStyle(.white)
            .font(.caption)
            .clipShape(Capsule())
        }
      }
      .imageStyle(width: 120, height: 160)
      .imageType(.subject)
      VStack(alignment: .leading) {
        HStack {
          if type != .none {
            Label(subject.category, systemImage: type.icon)
          }
          if !subject.airtime.date.isEmpty {
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

        NavigationLink(value: NavDestination.infobox("条目信息", subject.infobox)) {
          HStack {
            Text(subject.info)
              .font(.caption)
              .lineLimit(2)
            Spacer()
            Image(systemName: "chevron.right")
          }
        }.buttonStyle(.navLink)

        Spacer()

        HStack {
          Text(
            "\(subject.collection.doing) 人\(CollectionType.do.description(type))"
          )
          Text("/")
          Text(
            "\(subject.collection.collect) 人\(CollectionType.collect.description(type))"
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
                .foregroundStyle(.secondary)
              Spacer()
            }
          }.font(.footnote)
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
      SubjectRankView(rank: subject.rating.rank)
    }
  }
}

struct SubjectLockView: View {
  var body: some View {
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
}

struct SubjectRankView: View {
  let rank: Int

  var body: some View {
    BorderView(color: .accent, padding: 5) {
      HStack {
        Spacer()
        Label("Bangumi Ranked:", systemImage: "chart.bar.xaxis")
        Text("#\(rank)")
        Spacer()
      }
      .font(.callout)
      .foregroundStyle(.accent)
    }.padding(5)
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectHeaderView().environment(Subject.previewBook)
    }
  }.padding()
}
