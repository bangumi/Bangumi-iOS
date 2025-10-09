import Flow
import SwiftData
import SwiftUI

struct SubjectLargeRowView: View {
  @Environment(\.modelContext) var modelContext

  @Environment(Subject.self) var subject

  var body: some View {
    HStack {
      ImageView(img: subject.images?.resize(.r200))
        .imageStyle(width: 90, height: 120)
        .imageType(.subject)
        .imageNSFW(subject.nsfw)
        .imageLink(subject.link)
      VStack(alignment: .leading) {
        // title
        HStack {
          VStack(alignment: .leading) {
            HStack {
              if subject.typeEnum != .none {
                Image(systemName: subject.typeEnum.icon)
                  .foregroundStyle(.secondary)
                  .font(.footnote)
              }
              Text(subject.name.withLink(subject.link))
                .font(.headline)
                .lineLimit(1)
            }
          }
          Spacer()
          if subject.rating.rank > 0 {
            Label(String(subject.rating.rank), systemImage: "chart.bar.xaxis")
              .foregroundStyle(.accent)
              .font(.footnote)
          }
        }

        // subtitle
        HStack {
          if !subject.nameCN.isEmpty {
            Text(subject.nameCN)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer()

        // meta
        if !subject.info.isEmpty {
          Spacer()
          Text(subject.info)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        // tags
        HStack(spacing: 4) {
          if !subject.category.isEmpty {
            BorderView {
              Text(subject.category).fixedSize()
            }
          }
          if !subject.metaTags.isEmpty {
            ForEach(subject.metaTags, id: \.self) { tag in
              Text(tag)
                .fixedSize()
                .padding(2)
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
          }
        }
        .foregroundStyle(.secondary)
        .font(.caption)

        // rating
        HStack {
          if subject.rating.total > 10 {
            if subject.rating.score > 0 {
              StarsView(score: subject.rating.score, size: 12)
              Text("\(subject.rating.score.rateDisplay)")
                .font(.callout)
                .foregroundStyle(.orange)
              if subject.rating.total > 0 {
                Text("(\(subject.rating.total)人评分)")
                  .foregroundStyle(.secondary)
              }
            }
          } else {
            StarsView(score: 0, size: 12)
            Text("(少于10人评分)")
              .foregroundStyle(.secondary)
          }
          Spacer()
          if let interest = subject.interest {
            Label(
              interest.type.description(subject.typeEnum),
              systemImage: interest.type.icon
            )
            .foregroundStyle(.accent)
          }
        }
        .font(.footnote)
      }.padding(.leading, 2)
    }
    .frame(height: 120)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

struct SubjectItemView: View {
  let subjectId: Int

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId

    let desc = FetchDescriptor<Subject>(
      predicate: #Predicate<Subject> {
        return $0.subjectId == subjectId
      }
    )
    _subjects = Query(desc)
  }

  var body: some View {
    CardView {
      SubjectLargeRowView()
        .environment(subject)
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  let episodes = Episode.previewAnime
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectLargeRowView()
        .environment(subject)
    }.padding()
  }.modelContainer(container)
}
