import SwiftUI

extension TimelineDTO {
  /// Placeholder data for skeletons: it only shapes the real row layout before redaction
  /// grays everything out, so field values are never visible to the user.
  static func skeleton(id: Int) -> TimelineDTO {
    TimelineDTO(
      id: id, uid: 0, cat: .status, type: 0, memo: TimelineMemoDTO(), batch: false,
      source: TimelineSource(name: "", url: nil), replies: 0, createdAt: 0,
      user: SlimUserDTO(Profile()), reactions: nil)
  }
}

extension SubjectDTO {
  /// Placeholder subject for the detail skeleton: it shapes the real header layout
  /// before redaction grays everything out, so field values are never visible.
  static var skeleton: SubjectDTO {
    SubjectDTO(
      id: 0, airtime: SubjectAirtime(date: nil), collection: [:], eps: 0, infobox: [],
      info: "占位简介", locked: false, metaTags: [], tags: [], name: "占位条目名称",
      nameCN: "占位中文名", nsfw: false, platform: SubjectPlatform(name: "TV"),
      rating: SubjectRating(), redirect: 0, series: false, seriesEntry: 0, summary: "",
      type: .anime, volumes: 0)
  }
}

/// Skeleton bar; redaction does not gray out Shape fills, so draw bars in track color
/// to match the redacted placeholder text.
private struct SkeletonBar: View {
  var width: CGFloat? = nil
  let height: CGFloat

  @Environment(\.theme) private var theme

  var body: some View {
    RoundedRectangle(cornerRadius: height / 4, style: .continuous)
      .fill(theme.track)
      .frame(width: width, height: height)
      .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
  }
}

struct TimelineListSkeleton: View {
  var rowCount: Int = 6

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(0..<rowCount, id: \.self) { index in
        TimelineItemView(item: .skeleton(id: index), previousUID: nil)
          .padding(.bottom, 8)
      }
    }
    .padding(.horizontal, 8)
    .redacted(reason: .placeholder)
    .shimmer()
    .allowsHitTesting(false)
  }
}

struct SubjectDetailSkeleton: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading) {
        SubjectHeaderView(subject: .skeleton) {}

        SkeletonBar(height: 40)
          .padding(.top, 8)

        HStack(spacing: 6) {
          ForEach(0..<6, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .fill(theme.track)
              .frame(width: 34, height: 34)
          }
          Spacer(minLength: 0)
        }
        .padding(.top, 4)

        SkeletonBar(width: 120, height: 13)
          .padding(.top, 8)
        SkeletonBar(height: 12)
        SkeletonBar(height: 12)
        SkeletonBar(width: 180, height: 12)

        SkeletonBar(width: 120, height: 13)
          .padding(.top, 8)
        HStack(spacing: 8) {
          ForEach(0..<4, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(theme.track)
              .frame(width: 60, height: 84)
          }
          Spacer(minLength: 0)
        }

        Spacer()
      }
      .padding(.horizontal, 8)
    }
    .redacted(reason: .placeholder)
    .shimmer()
    .allowsHitTesting(false)
  }
}

struct ProgressSubjectsSkeleton: View {
  let mode: ProgressViewMode

  @Environment(\.theme) private var theme
  @Environment(\.colorScheme) private var colorScheme

  private var cardShadow: Color? {
    colorScheme == .dark ? .clear : nil
  }

  var body: some View {
    Group {
      switch mode {
      case .list:
        listSkeleton
      case .tile:
        tileSkeleton
      }
    }
    .shimmer()
    .allowsHitTesting(false)
  }

  private var listSkeleton: some View {
    VStack(spacing: 8) {
      ForEach(0..<4, id: \.self) { _ in
        CardView(cornerRadius: 12, shadow: cardShadow) {
          HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(theme.track)
              .frame(width: 56, height: 80)
            VStack(alignment: .leading, spacing: 4) {
              SkeletonBar(width: 150, height: 15)
              SkeletonBar(width: 100, height: 11)
              Spacer(minLength: 0)
              HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                  RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(theme.track)
                    .frame(width: 28, height: 28)
                }
              }
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
          }
        }
      }
    }
    .padding(.horizontal, 8)
  }

  private var tileSkeleton: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
      ForEach(0..<6, id: \.self) { _ in
        CardView(padding: 8, cornerRadius: 12, shadow: cardShadow) {
          VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(theme.track)
              .aspectRatio(0.707, contentMode: .fit)
            SkeletonBar(width: 90, height: 13)
            SkeletonBar(width: 60, height: 11)
            SkeletonBar(height: 30)
          }
        }
      }
    }
    .padding(.horizontal, 8)
  }
}
