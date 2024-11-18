//
//  CalendarView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import OSLog
import SwiftData
import SwiftUI

struct CalendarView: View {

  @State private var refreshed: Bool = false

  @Query(sort: \BangumiCalendar.weekdayId)
  private var calendars: [BangumiCalendar]

  var sortedCalendars: [BangumiCalendar] {
    let calendar = Calendar.current
    // FIXME: something wrong with weekday for today
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
      Logger.app.error("Could not get yesterday")
      return calendars
    }
    let weekday = calendar.component(.weekday, from: yesterday)
    return calendars.sorted { (cal1: BangumiCalendar, cal2: BangumiCalendar) -> Bool in
      if cal1.weekdayId >= weekday && cal2.weekdayId < weekday {
        return true
      } else if cal1.weekdayId < weekday && cal2.weekdayId >= weekday {
        return false
      } else {
        return cal1.weekdayId < cal2.weekdayId
      }
    }
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
        LazyVStack {
          ForEach(sortedCalendars) { calendar in
            CalendarWeekdayView(calendar: calendar).padding(.vertical, 10)
          }
        }.padding(.horizontal, 8)
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
  let calendar: BangumiCalendar

  var body: some View {
    VStack {
      Text(calendar.weekday.cn).font(.title3)
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
      ]) {
        ForEach(calendar.items, id: \.id) { subject in
          NavigationLink(value: NavDestination.subject(subjectId: subject.id)) {
            VStack {
              ImageView(img: subject.images?.common, width: 80, height: 80, type: .subject)
              Text(subject.name).font(.caption).multilineTextAlignment(.leading).lineLimit(1)
            }
          }.buttonStyle(.plain)
        }
      }
    }
  }
}
