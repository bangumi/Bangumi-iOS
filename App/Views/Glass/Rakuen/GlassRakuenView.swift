import SwiftUI

struct GlassRakuenView: View {
  @AppStorage("rakuenListMode") var rakuenListMode: RakuenListMode = .subjectTrending
  @AppStorage("isAuthenticated") var isAuthenticated = false
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.theme) private var theme

  @State private var reloader = false
  @State private var showMoreSheet = false
  @State private var pendingDestination: NavDestination?
  @State private var moreDestination: NavDestination?
  @State private var revertedMode: RakuenListMode?

  private var modeBinding: Binding<RakuenListMode> {
    Binding(
      get: { rakuenListMode },
      set: { newValue in
        revertedMode = nil
        rakuenListMode = newValue
      })
  }

  private func pushPendingDestination() {
    guard let destination = pendingDestination else { return }
    pendingDestination = nil
    moreDestination = destination
  }

  private func revertModeIfNeeded() {
    guard !isAuthenticated, rakuenListMode.requiresLogin else { return }
    let previous = rakuenListMode
    withAnimation(.default) {
      revertedMode = previous
      rakuenListMode = .subjectTrending
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        if let revertedMode {
          GlassLoginHintBar(
            text: "上次的筛选「\(revertedMode.description)」需要登录，已退回「热门」。")
        }
        HotGroupsView()
        GlassRakuenFilters(selection: modeBinding, isAuthenticated: isAuthenticated)
        contentView
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
    .refreshable {
      withAnimation(.default) {
        reloader.toggle()
      }
    }
    .navigationTitle("超展开")
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        leadingToolbarItem
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showMoreSheet = true
        } label: {
          ToolbarCircle {
            Image(systemName: "ellipsis")
              .font(.callout.weight(.bold))
          }
        }
      }
    }
    .navigationDestination(item: $moreDestination) { destination in
      destination
    }
    .sheet(isPresented: $showMoreSheet, onDismiss: pushPendingDestination) {
      GlassRakuenMoreSheet(isAuthenticated: isAuthenticated) { destination in
        pendingDestination = destination
        showMoreSheet = false
      }
    }
    .onAppear {
      revertModeIfNeeded()
    }
    .onChange(of: isAuthenticated) { _, _ in
      revertedMode = nil
      revertModeIfNeeded()
    }
  }

  @ViewBuilder
  private var leadingToolbarItem: some View {
    if isAuthenticated {
      NavigationLink(value: NavDestination.profileHome) {
        ProfileToolbarAvatarView(imageURL: profile.avatar?.large)
      }
      .buttonStyle(.plain)
    } else {
      GlassAuthButton {
        ToolbarCircle {
          Image(systemName: "person.crop.circle")
        }
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch rakuenListMode.category {
    case .subject:
      if let mode = rakuenListMode.subjectTopicMode {
        CachedSubjectTopicListView(mode: mode, reloader: $reloader)
      }
    case .group:
      if let mode = rakuenListMode.groupTopicMode {
        CachedGroupTopicListView(mode: mode, reloader: $reloader)
      }
    }
  }
}
