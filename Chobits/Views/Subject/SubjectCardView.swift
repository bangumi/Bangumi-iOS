import SwiftData
import SwiftUI

struct SubjectTinyView: View {
  let subject: SlimSubjectDTO

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      HStack {
        ImageView(img: subject.images?.small)
          .imageStyle(width: 32, height: 32)
          .imageType(.subject)
        VStack(alignment: .leading) {
          Text(subject.title)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 40)
    .subjectPreview(subject)
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
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 60, height: 72)
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
        VStack(alignment: .leading) {
          Text(subject.title)
          Text(subject.info ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
          ratingLine
            .font(.footnote)
            .foregroundStyle(.secondary)
        }.lineLimit(1)
        Spacer(minLength: 0)
      }
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 80)
    .subjectPreview(subject, eps: true)
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
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 80, height: 108, cornerRadius: 16)
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
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
          Text(subject.info ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
          Spacer()
          ratingLine
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
  }
}

extension View {
  func subjectPreview(_ subject: SlimSubjectDTO, eps: Bool = false) -> some View {
    self.contextMenu {
      NavigationLink(value: NavDestination.subject(subject.id)) {
        Label("查看详情", systemImage: "magnifyingglass")
      }
      if eps, subject.type == .anime || subject.type == .real {
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
