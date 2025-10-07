import SwiftUI

struct UserIndexesView: View {

  @Environment(User.self) var user

  @State private var indexes: [SlimIndexDTO] = []

  func refresh() async {
    do {
      let resp = try await Chii.shared.getUserIndexes(
        username: user.username, limit: 5)
      indexes = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          NavigationLink(value: NavDestination.userIndex(user.slim)) {
            Text("目录").font(.title3)
          }.buttonStyle(.navigation)
          Spacer()
        }
        .padding(.top, 8)
        .task(refresh)
        Divider()
      }

      ForEach(indexes) { index in
        VStack {
          UserIndexItemView(index: index)
          Divider()
        }
      }
    }.animation(.default, value: indexes)
  }
}

struct UserIndexItemView: View {
  let index: SlimIndexDTO

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(index.title.withLink(index.link))
        HStack(spacing: 2) {
          Text("创建").foregroundStyle(.secondary.opacity(0.5))
          Text(index.createdAt.datetimeDisplay).foregroundStyle(.secondary)
          Text(" • ").foregroundStyle(.secondary.opacity(0.5))
          Text("更新").foregroundStyle(.secondary.opacity(0.5))
          Text(index.updatedAt.datetimeDisplay).foregroundStyle(.secondary)
        }.font(.footnote)
        HStack(spacing: 5) {
          if let count = index.stats.subject.book, count > 0 {
            Label("\(count)", systemImage: SubjectType.book.icon)
          }
          if let count = index.stats.subject.anime, count > 0 {
            Label("\(count)", systemImage: SubjectType.anime.icon)
          }
          if let count = index.stats.subject.music, count > 0 {
            Label("\(count)", systemImage: SubjectType.music.icon)
          }
          if let count = index.stats.subject.game, count > 0 {
            Label("\(count)", systemImage: SubjectType.game.icon)
          }
          if let count = index.stats.subject.real, count > 0 {
            Label("\(count)", systemImage: SubjectType.real.icon)
          }
          if let count = index.stats.character, count > 0 {
            Label("\(count)", systemImage: IndexRelatedCategory.character.icon)
          }
          if let count = index.stats.person, count > 0 {
            Label("\(count)", systemImage: IndexRelatedCategory.person.icon)
          }
          if let count = index.stats.episode, count > 0 {
            Label("\(count)", systemImage: IndexRelatedCategory.episode.icon)
          }
          if let count = index.stats.blog, count > 0 {
            Label("\(count)", systemImage: IndexRelatedCategory.blog.icon)
          }
          if let count = index.stats.groupTopic, count > 0 {
            Label("\(count)", systemImage: IndexRelatedCategory.groupTopic.icon)
          }
          if let count = index.stats.subjectTopic, count > 0 {
            Label("\(count)", systemImage: IndexRelatedCategory.subjectTopic.icon)
          }
        }
        .labelStyle(.compact)
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
  }
}
