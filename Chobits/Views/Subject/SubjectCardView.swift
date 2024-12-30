import SwiftData
import SwiftUI

struct SubjectTinyView: View {
  let subject: SlimSubjectDTO

  var body: some View {
    HStack {
      ImageView(img: subject.images?.grid)
        .imageStyle(width: 32, height: 32)
        .imageType(.subject)
      VStack(alignment: .leading) {
        Text("\(subject.nameCN.isEmpty ? subject.name : subject.nameCN)")
          .lineLimit(1)
      }
      Spacer()
    }
    .padding(5)
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .inset(by: 1)
        .stroke(.secondary.opacity(0.2), lineWidth: 1)
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 40)
    .contextMenu {
      NavigationLink(value: NavDestination.subject(subject.id)) {
        Label("查看详情", systemImage: "magnifyingglass")
      }
    } preview: {
      SubjectCardView(subject: subject)
        .padding()
        .frame(idealWidth: 360)
    }
  }
}

struct SubjectSmallView: View {
  let subject: SlimSubjectDTO

  var ratingLine: Text {
    guard let rating = subject.rating else {
      return Text("")
    }
    var text: [Text] = []
    if rating.rank > 0, rating.rank < 1000 {
      text.append(Text("#\(rating.rank) "))
    }
    if rating.score > 0 {
      let img = Image(systemName: "star.fill")
      text.append(Text("\(img)").font(.system(size: 10)).baselineOffset(1))
      let score = String(format: "%.1f", rating.score)
      text.append(Text(" \(score)"))
    }
    if rating.total > 10 {
      text.append(Text(" (\(rating.total))"))
    }
    return text.reduce(Text(""), +)
  }

  var body: some View {

    HStack {
      ImageView(img: subject.images?.resize(.r200)) {
        if subject.nsfw {
          NSFWBadgeView()
        }
      }
      .imageStyle(width: 60, height: 72)
      .imageType(.subject)
      VStack(alignment: .leading) {
        Text("\(subject.nameCN.isEmpty ? subject.name : subject.nameCN)")
        Text(subject.info)
          .font(.footnote)
          .foregroundStyle(.secondary)
        ratingLine
          .font(.footnote)
          .foregroundStyle(.secondary)
      }.lineLimit(1)
      Spacer()
    }
    .padding(5)
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .inset(by: 1)
        .stroke(.secondary.opacity(0.2), lineWidth: 1)
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 80)
    .contextMenu {
      NavigationLink(value: NavDestination.subject(subject.id)) {
        Label("查看详情", systemImage: "magnifyingglass")
      }
      if subject.type == .anime || subject.type == .real {
        NavigationLink(value: NavDestination.episodeList(subject.id)) {
          Label("章节列表", systemImage: "list.bullet")
        }
      }
    } preview: {
      SubjectCardView(subject: subject)
        .padding()
        .frame(idealWidth: 360)
    }
  }
}

struct SubjectCardView: View {
  let subject: SlimSubjectDTO

  var ratingLine: Text {
    guard let rating = subject.rating else {
      return Text("")
    }
    var text: [Text] = []
    if rating.rank > 0, rating.rank < 1000 {
      text.append(Text("#\(rating.rank) "))
    }
    if rating.score > 0 {
      let img = Image(systemName: "star.fill")
      text.append(Text("\(img)").foregroundStyle(.orange).baselineOffset(1))
      let score = String(format: "%.1f", rating.score)
      text.append(Text(" \(score)"))
    }
    if rating.total > 10 {
      text.append(Text(" (\(rating.total)人评分)"))
    }
    return text.reduce(Text(""), +)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .top) {
        ImageView(img: subject.images?.resize(.r200)) {
          if subject.nsfw {
            NSFWBadgeView()
          }
        }
        .imageStyle(width: 80, height: 108)
        .imageType(.subject)
        VStack(alignment: .leading) {
          Text(subject.name)
            .font(.headline)
            .lineLimit(1)
          if !subject.nameCN.isEmpty {
            Text(subject.nameCN)
              .font(.subheadline)
              .lineLimit(1)
          }
          Spacer()
          Text(subject.info)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
          Spacer()
          ratingLine
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer()
      }
    }
  }
}
