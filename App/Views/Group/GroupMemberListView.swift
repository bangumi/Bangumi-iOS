import SwiftUI

struct GroupMemberListView: View {
  let name: String

  @State private var creators: [GroupMemberDTO] = []
  @State private var moderators: [GroupMemberDTO] = []
  @State private var loadedModerators = false

  var title: String {
    "小组成员"
  }

  func loadModerators() async {
    if loadedModerators { return }
    do {
      let creatorResp = try await Chii.shared.getGroupMembers(name, role: .creator, limit: 100)
      creators = creatorResp.data
      let moderatorResp = try await Chii.shared.getGroupMembers(name, role: .moderator, limit: 100)
      moderators = moderatorResp.data
      loadedModerators = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadMembers(limit: Int, offset: Int) async -> PagedDTO<GroupMemberDTO>? {
    do {
      let resp = try await Chii.shared.getGroupMembers(
        name, role: .member, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        if !creators.isEmpty {
          Section {
            VStack(alignment: .leading, spacing: 4) {
              Text("小组长")
                .font(.title3)
              Divider()
              ForEach(creators) { member in
                GroupMemberItemView(member: member)
              }
            }
          }
        }

        if !moderators.isEmpty {
          Section {
            VStack(alignment: .leading, spacing: 4) {
              Text("管理员")
                .font(.title3)
              Divider()
              ForEach(moderators) { member in
                GroupMemberItemView(member: member)
              }
            }
          }
        }

        Section {
          VStack(alignment: .leading, spacing: 4) {
            Text("成员")
              .font(.title3)
            Divider()
            PageView<GroupMemberDTO, _>(nextPageFunc: loadMembers) { member in
              GroupMemberItemView(member: member)
            }
          }
        }
      }.padding(8)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await loadModerators()
      }
    }
  }
}

struct GroupMemberItemView: View {
  let member: GroupMemberDTO

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        ImageView(img: member.user?.avatar?.large)
          .imageStyle(width: 60, height: 60)
          .imageType(.avatar)
          .imageLink(member.user?.link ?? "")
        VStack(alignment: .leading) {
          HStack {
            VStack(alignment: .leading) {
              Text(member.user?.header ?? "")
                .lineLimit(1)
              Divider()
              Text("@\(member.user?.username ?? "")")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
          }
        }.padding(.leading, 4)
      }
    }
  }
}
