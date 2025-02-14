import SwiftUI

struct GroupMemberListView: View {
  let name: String

  @State private var moderators: [GroupMemberDTO] = []
  @State private var loadedModerators = false

  var title: String {
    "小组成员"
  }

  func loadModerators() async {
    if loadedModerators { return }
    do {
      let resp = try await Chii.shared.getGroupMembers(name, moderator: true, limit: 100)
      moderators = resp.data
      loadedModerators = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadMembers(limit: Int, offset: Int) async -> PagedDTO<GroupMemberDTO>? {
    do {
      let resp = try await Chii.shared.getGroupMembers(
        name, moderator: false, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        if !moderators.isEmpty {
          Section {
            VStack(alignment: .leading, spacing: 4) {
              Text("管理员")
                .font(.title3)
              Divider()
              ForEach(moderators) { member in
                CardView {
                  HStack(alignment: .top) {
                    ImageView(img: member.user?.avatar?.large)
                      .imageStyle(width: 60, height: 60)
                      .imageType(.avatar)
                      .imageLink(member.user?.link ?? "")
                    VStack(alignment: .leading) {
                      HStack {
                        VStack(alignment: .leading) {
                          Text(member.user?.nickname.withLink(member.user?.link) ?? "")
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
          }
          Divider()
            .padding(.vertical, 4)
        }

        Section {
          VStack(alignment: .leading, spacing: 4) {
            Text("成员")
              .font(.title3)
            Divider()
            PageView<GroupMemberDTO, _>(nextPageFunc: loadMembers) { member in
              CardView {
                HStack(alignment: .top) {
                  ImageView(img: member.user?.avatar?.large)
                    .imageStyle(width: 60, height: 60)
                    .imageType(.avatar)
                    .imageLink(member.user?.link ?? "")
                  VStack(alignment: .leading) {
                    HStack {
                      VStack(alignment: .leading) {
                        Text(member.user?.nickname.withLink(member.user?.link) ?? "")
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
