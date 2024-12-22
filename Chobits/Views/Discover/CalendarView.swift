import Flow
import OSLog
import SwiftData
import SwiftUI

func getWeekday(_ date: Date) -> Int {
  return [0, 7, 1, 2, 3, 4, 5, 6][Calendar.current.component(.weekday, from: date)]
}

struct CalendarView: View {

  @State private var refreshed: Bool = false

  @Query(sort: \BangumiCalendar.weekday)
  private var calendars: [BangumiCalendar]

  var today: Date {
    Date()
  }

  var sortedCalendars: [BangumiCalendar] {
    let weekday = getWeekday(today)
    return calendars.sorted { (cal1: BangumiCalendar, cal2: BangumiCalendar) -> Bool in
      if cal1.weekday >= weekday && cal2.weekday < weekday {
        return true
      } else if cal1.weekday < weekday && cal2.weekday >= weekday {
        return false
      } else {
        return cal1.weekday < cal2.weekday
      }
    }
  }

  var total: Int {
    calendars.reduce(0) { $0 + $1.items.count }
  }

  var todayTotal: Int {
    sortedCalendars.first?.items.count ?? 0
  }

  var todayWatchers: Int {
    sortedCalendars.first?.items.reduce(0) { $0 + $1.watchers } ?? 0
  }

  func refreshCalendar() async {
    if refreshed { return }
    refreshed = true
    do {
      try await Chii.shared.loadCalendar()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    if calendars.isEmpty {
      ProgressView().task {
        await refreshCalendar()
      }
    } else {
      ScrollView {
        VStack {
          Text("每日放送")
            .font(.title)
            .padding(.top, 10)
          Text("\(today.formatted(date: .complete, time: .omitted))")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Text("本季度共 \(total) 部番组，今日上映 \(todayTotal) 部。共 \(todayWatchers) 人收看今日番组。")
            .foregroundStyle(.secondary)
        }.padding(.horizontal, 8)
        LazyVStack {
          ForEach(sortedCalendars) { calendar in
            CalendarWeekdayView()
              .environment(calendar)
              .padding(.vertical, 10)
          }
        }.padding(.horizontal, 8)
      }.refreshable {
        refreshed = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        await refreshCalendar()
      }
    }
  }
}

struct CalendarWeekdayView: View {
  @Environment(BangumiCalendar.self) var calendar

  var weekday: String {
    return Calendar.current.weekdaySymbols[calendar.weekday % 7]
  }

  var body: some View {
    VStack {
      Text(weekday).font(.title3)
      HFlow {
        ForEach(calendar.items, id: \.subject) { item in
          VStack {
            NavigationLink(value: NavDestination.subject(item.subject.id)) {
              ImageView(img: item.subject.images?.common) {
              } caption: {
                Text(item.subject.nameCN)
                  .multilineTextAlignment(.leading)
                  .padding(.horizontal, 2)
              }
              .imageStyle(width: 96, height: 128)
              .imageType(.subject)
            }.buttonStyle(.navLink)
            Text(item.subject.name)
              .font(.caption)
              .lineLimit(1)
              .frame(width: 96)
          }
        }
      }
    }
  }
}
