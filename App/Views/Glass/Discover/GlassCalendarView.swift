import OSLog
import SwiftUI

struct GlassCalendarView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.theme) private var theme

  @State private var currentDate = Calendar.current.startOfDay(for: Date())
  @State private var refreshed: Bool = false
  @State private var calendars: [CalendarEntryDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

  private var sortedCalendars: [CalendarEntryDTO] {
    let todayWeekday = WeekDay(date: currentDate).rawValue
    let sorted = calendars.sorted { $0.weekday < $1.weekday }
    guard let pivot = sorted.firstIndex(where: { $0.weekday >= todayWeekday }) else {
      return sorted
    }
    return Array(sorted[pivot...] + sorted[..<pivot])
  }

  private var total: Int {
    calendars.reduce(0) { $0 + $1.items.count }
  }

  private var todayTotal: Int {
    sortedCalendars.first?.items.count ?? 0
  }

  private var todayWatchers: Int {
    sortedCalendars.first?.items.reduce(0) { $0 + $1.watchers } ?? 0
  }

  private static func subjectIds(in calendars: [CalendarEntryDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(
      calendars.flatMap { $0.items.map(\.subject.id) }
    )
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

  private func updateCurrentDate() {
    let today = Calendar.current.startOfDay(for: Date())
    if currentDate != today {
      withAnimation(.default) {
        currentDate = today
      }
    }
  }

  private func refreshCalendar() async {
    if refreshed { return }
    refreshed = true
    do {
      try await DiscoveryRepository.loadCalendar()
      await loadCachedCalendar()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private var summaryCard: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(spacing: 6) {
        Text("每日放送")
          .font(.title3.weight(.heavy))
          .foregroundStyle(theme.title)
        Text(currentDate.formatted(date: .complete, time: .omitted))
          .font(.footnote)
          .foregroundStyle(theme.secondaryText)
        Text("本季度共 \(total) 部番组，今日上映 \(todayTotal) 部。")
          .font(.footnote)
          .foregroundStyle(theme.secondaryText)
        Text("共 \(todayWatchers) 人收看今日番组。")
          .font(.footnote)
          .foregroundStyle(theme.secondaryText)
      }
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
    }
  }

  var body: some View {
    Group {
      if calendars.isEmpty {
        ProgressView().task {
          await loadCachedCalendar()
          await refreshCalendar()
        }
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            summaryCard
            ForEach(sortedCalendars) { calendar in
              GlassCalendarWeekdayView(
                calendar: calendar,
                collectionTypes: collectionTypes,
                reloadCollectionType: reloadCollectionType
              )
            }
          }
          .padding(.horizontal, theme.metrics.screenPadding)
          .padding(.top, 8)
          .padding(.bottom, 26)
        }
        .navigationTitle("每日放送")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
          refreshed = false
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          await refreshCalendar()
        }
      }
    }
    .onAppear {
      updateCurrentDate()
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

private struct GlassCalendarWeekdayView: View {
  let calendar: CalendarEntryDTO
  let collectionTypes: [Int: CollectionType]
  let reloadCollectionType: (Int) async -> Void

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  private var weekday: WeekDay {
    WeekDay(rawValue: calendar.weekday) ?? .mon
  }

  private var watchers: Int {
    calendar.items.reduce(0) { $0 + $1.watchers }
  }

  private var subtitle: String {
    guard !calendar.items.isEmpty else { return "暂无放送" }
    return "\(calendar.items.count) 部 · \(glassCompactCount(watchers)) 人在追"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      GlassDayBanner(
        title: "\(weekday.cn) · \(weekday.desc)",
        subtitle: subtitle,
        colors: theme.weekdayBanner(weekday)
      )
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 14) {
        ForEach(calendar.items) { item in
          let ctype = collectionTypes[item.subject.id] ?? CollectionType.none
          VStack(alignment: .leading, spacing: 5) {
            ImageView(img: item.subject.images?.resize(.r200))
              .imageStyle(aspectRatio: 0.707)
              .imageType(.subject)
              .overlay(alignment: .topTrailing) {
                GlassCollectionBadge(type: ctype, subjectType: item.subject.type)
                  .padding(5)
              }
              .imageNavLink(item.subject.link)
              .subjectPreview(item.subject, collectionType: ctype) {
                await reloadCollectionType(item.subject.id)
              }
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
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}
