import SwiftData
import SwiftUI

struct SubjectHeaderView: View {
  @Bindable var subject: Subject

  var type: SubjectType {
    subject.typeEnum
  }

  var collectStats: String {
    var text = ""
    if subject.collection.doing > 0 {
      text += "\(subject.collection.doing) 人\(CollectionType.doing.description(type))"
    }
    if subject.collection.collect > 0 {
      text += " / \(subject.collection.collect) 人\(CollectionType.collect.description(type))"
    }
    return text
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
      ImageView(img: subject.images?.resize(.r400))
        .imageStyle(width: 120, height: type.coverHeight(for: 120))
        .imageType(.subject)
        .imageNSFW(subject.nsfw)
        .enableSave(subject.images?.large)
        .padding(4)
        .shadow(radius: 4)
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
        if subject.nameCN.isEmpty {
          Text(subject.name)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .textSelection(.enabled)
        } else {
          Text(subject.nameCN)
            .multilineTextAlignment(.leading)
            .truncationMode(.middle)
            .lineLimit(2)
            .textSelection(.enabled)
        }
        Spacer()

        NavigationLink(value: NavDestination.subjectInfobox(subject.subjectId)) {
          HStack {
            Text(subject.info)
              .font(.caption)
              .lineLimit(2)
            Spacer()
            Image(systemName: "chevron.right")
          }
        }
        .buttonStyle(.navigation)
        .padding(.vertical, 4)
        Spacer()

        if !collectStats.isEmpty {
          Text(collectStats)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        if subject.rating.total > 10 {
          HStack {
            if subject.rating.score > 0 {
              StarsView(score: Float(subject.rating.score), size: 12)
              Text("\(subject.rating.score.rateDisplay)")
                .foregroundStyle(.orange)
                .font(.callout)
              Text("(\(subject.rating.total) 人评分)")
                .foregroundStyle(.secondary)
                .lineLimit(1)
              Spacer()
            }
          }.font(.footnote)
        } else {
          HStack {
            StarsView(score: 0, size: 12)
            Text("(少于 10 人评分)")
              .foregroundStyle(.secondary)
          }.font(.footnote)
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
        MusumeView(index: 0, width: 40, height: 60)
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
      SubjectHeaderView(subject: Subject.previewBook)
    }.padding()
  }
}
