import SwiftData
import SwiftUI

struct ProgressListView: View {
  let subjectIds: [Int]

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(subjectIds, id: \.self) { subjectId in
        ProgressSubjectContainerView(subjectId: subjectId) { subject, episodes in
          CardView {
            ProgressListItemContentView(
              subject: subject,
              episodes: episodes
            )
          }
          .transition(.opacity)
        }
      }
    }
    .padding(.horizontal, 8)
  }
}

struct ProgressListItemContentView: View {
  @Bindable var subject: Subject
  let episodes: [Episode]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    let subjectId = subject.subjectId
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.subject)
          .imageBadge(show: subject.interest?.private ?? false) {
            Image(systemName: "lock")
          }
          .imageNavLink(subject.link)
        VStack(alignment: .leading, spacing: 4) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading, spacing: 4) {
              Text(subject.title(with: titlePreference))
                .font(.headline)
                .lineLimit(1)
              ProgressSecondLineView(subject: subject)
            }
          }.buttonStyle(.scale)

          Spacer()

          switch subject.typeEnum {
          case .anime, .real:
            EpisodeRecentView(subject: subject, mode: .list, episodes: episodes)

          case .book:
            SubjectBookChaptersView(subject: subject, mode: .row)

          default:
            Label(
              subject.typeEnum.description,
              systemImage: subject.typeEnum.icon
            )
            .foregroundStyle(.accent)
            .font(.callout)
          }
        }
      }

      Section {
        switch subject.typeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(
              value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
              total: Float(subject.eps))
            ProgressView(
              value: Float(min(subject.volumes, subject.interest?.volStatus ?? 0)),
              total: Float(subject.volumes))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(
            value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
            total: Float(subject.eps)
          )
          .progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0)
            .progressViewStyle(.linear)
        }
      }
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
      ProgressListView(subjectIds: [subject.subjectId])
        .modelContainer(container)
    }.padding()
  }
}
