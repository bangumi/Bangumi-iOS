import OSLog
import SwiftData
import SwiftUI

func getWeekday(_ date: Date) -> Int {
  return [0, 7, 1, 2, 3, 4, 5, 6][Calendar.current.component(.weekday, from: date)]
}

struct CalendarView: View {

  @State private var refreshed: Bool = false
  @State private var width: CGFloat = 0

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
          VStack {
            Text("\(today.formatted(date: .complete, time: .omitted))")
            Text("本季度共 \(total) 部番组，今日上映 \(todayTotal) 部。")
            Text("共 \(todayWatchers) 人收看今日番组。")
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
        }.padding(.horizontal, 8)
        LazyVStack {
          ForEach(sortedCalendars) { calendar in
            CalendarWeekdayView(width: width)
              .environment(calendar)
              .padding(.vertical, 10)
          }
        }.padding(.horizontal, 8)
      }
      .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
      } action: { newSize in
        if self.width != newSize.width {
          self.width = newSize.width
        }
      }
      .refreshable {
        refreshed = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        await refreshCalendar()
      }
    }
  }
}

struct CalendarWeekdayView: View {
  let width: CGFloat

  @Environment(BangumiCalendar.self) var calendar

  var weekday: String {
    return Calendar.current.weekdaySymbols[calendar.weekday % 7]
  }

  var columnCount: Int {
    let columns = Int((width - 16) / 110)
    return columns > 0 ? columns : 1
  }

  var columns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: columnCount)
  }

  var body: some View {
    VStack {
      Text(weekday).font(.title3)
      LazyVGrid(columns: columns) {
        ForEach(calendar.items, id: \.subject) { item in
          VStack {
            ImageView(img: item.subject.images?.resize(.r200)) {
            } caption: {
              Text(item.subject.title)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(.horizontal, 2)
            }
            .imageStyle(width: 110, height: 140)
            .imageType(.subject)
            .imageLink(item.subject.link)
          }
        }
      }
    }
  }
}
