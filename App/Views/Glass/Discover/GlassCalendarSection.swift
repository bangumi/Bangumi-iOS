import OSLog
import SwiftUI

struct GlassCalendarSection: View {
  let reloadToken: Int

  private struct CalendarDay: Identifiable {
    let weekday: WeekDay
    let desc: String
    let calendar: CalendarEntryDTO

    var id: WeekDay {
      weekday
    }

    var count: Int {
      calendar.items.count
    }

    var watchers: Int {
      calendar.items.reduce(0) { $0 + $1.watchers }
    }
  }

  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.theme) private var theme

  @State private var currentDate = Calendar.current.startOfDay(for: Date())
  @State private var calendars: [CalendarEntryDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

  private var dates: [CalendarDay] {
    let today = currentDate
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

    let todayCalendar =
      calendars.first { $0.weekday == WeekDay(date: today).rawValue }
      ?? CalendarEntryDTO(weekday: WeekDay(date: today).rawValue, items: [])
    let tomorrowCalendar =
      calendars.first { $0.weekday == WeekDay(date: tomorrow).rawValue }
      ?? CalendarEntryDTO(weekday: WeekDay(date: tomorrow).rawValue, items: [])

    return [
      CalendarDay(weekday: WeekDay(date: today), desc: "今天", calendar: todayCalendar),
      CalendarDay(weekday: WeekDay(date: tomorrow), desc: "明天", calendar: tomorrowCalendar),
    ]
  }

  private static func subjectIds(in calendars: [CalendarEntryDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(
      calendars.flatMap { $0.items.map(\.subject.id) }
    )
  }

  private func updateCurrentDate() {
    let today = Calendar.current.startOfDay(for: Date())
    if currentDate != today {
      withAnimation(.default) {
        currentDate = today
      }
    }
  }

  private func loadCachedCalendar() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedCalendars = try await db.fetchCalendarEntries()
      let fetchedCollectionTypes = try await SubjectCollectionTypeResolver.load(
        subjectIds: Self.subjectIds(in: fetchedCalendars)
      )
      withAnimation(.default) {
        calendars = fetchedCalendars
        collectionTypes = fetchedCollectionTypes
      }
    } catch {
      Logger.app.error("Failed to load cached calendar: \(error)")
    }
  }

  private func reloadCollectionType(subjectId: Int) async {
    do {
      let fetchedCollectionTypes = try await SubjectCollectionTypeResolver.load(
        subjectIds: [subjectId]
      )
      withAnimation(.default) {
        collectionTypes[subjectId] = fetchedCollectionTypes[subjectId] ?? CollectionType.none
      }
    } catch {
      Logger.app.error("Failed to load calendar collection type: \(error)")
    }
  }

  private func handleSubjectInvalidation(_ notification: Notification) {
    guard let subjectId = ProgressSubjectInvalidation.subjectId(from: notification),
      Self.subjectIds(in: calendars).contains(subjectId)
    else { return }
    Task {
      await reloadCollectionType(subjectId: subjectId)
    }
  }

  private func subtitle(for item: CalendarDay) -> String {
    guard item.count > 0 else { return "暂无放送" }
    return "\(item.count) 部 · \(glassCompactCount(item.watchers)) 人在追"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if calendars.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
      } else {
        ThemedSectionHeader(
          "每日放送 · \(currentDate.formatted(date: .long, time: .omitted))"
        ) {
          NavigationLink(value: NavDestination.calendar) {
            GlassMoreLabel(title: "更多 »")
          }
          .buttonStyle(.plain)
        }
        ForEach(dates) { item in
          VStack(alignment: .leading, spacing: 10) {
            GlassDayBanner(
              title: "\(item.desc) · \(item.weekday.cn)",
              subtitle: subtitle(for: item),
              colors: theme.weekdayBanner(item.weekday)
            )
            if item.count > 0 {
              GlassCalendarCoverRow(
                calendar: item.calendar,
                collectionTypes: collectionTypes,
                reloadCollectionType: reloadCollectionType
              )
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear {
      updateCurrentDate()
    }
    .task(id: reloadToken) {
      await loadCachedCalendar()
    }
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        updateCurrentDate()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
      updateCurrentDate()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: ProgressSubjectInvalidation.notificationName),
      perform: handleSubjectInvalidation
    )
  }
}

private struct GlassCalendarCoverRow: View {
  let calendar: CalendarEntryDTO
  let collectionTypes: [Int: CollectionType]
  let reloadCollectionType: (Int) async -> Void

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  static let cardWidth: CGFloat = 88
  static let cardHeight: CGFloat = 122

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top, spacing: 10) {
        ForEach(calendar.items) { item in
          let ctype = collectionTypes[item.subject.id] ?? CollectionType.none
          VStack(alignment: .leading, spacing: 5) {
            ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
              .imageStyle(width: Self.cardWidth, height: Self.cardHeight)
              .imageType(.subject)
              .overlay(alignment: .topTrailing) {
                GlassCollectionBadge(type: ctype, subjectType: item.subject.type)
                  .padding(5)
              }
              .imageNavLink(item.subject.link)
              .subjectPreview(item.subject, collectionType: ctype) {
                await reloadCollectionType(item.subject.id)
              }
            VStack(alignment: .leading, spacing: 5) {
              Text(item.subject.title(with: titlePreference))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.cardTitle)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
              if item.watchers > 10 {
                Text("\(glassCompactCount(item.watchers)) 人在追")
                  .font(.caption2.weight(.semibold).monospaced())
                  .foregroundStyle(theme.tertiaryText)
                  .lineLimit(1)
              }
            }
            .glassReservedCaption(title: .caption, detail: .caption2, spacing: 5)
          }
          .frame(width: Self.cardWidth, alignment: .leading)
        }
      }.scrollTargetLayout()
    }
    .scrollClipDisabled()
    .scrollTargetBehavior(.viewAligned)
  }
}
