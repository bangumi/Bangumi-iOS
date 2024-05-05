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
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @Query(sort: \BangumiCalendar.id)
  private var calendars: [BangumiCalendar]

  var sortedCalendars: [BangumiCalendar] {
    let calendar = Calendar.current
    // FIXME: something wrong with weekday for today
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
      notifier.alert(message: "Could not get yesterday")
      return calendars
    }
    let weekday = calendar.component(.weekday, from: yesterday)
    return calendars.sorted { (cal1: BangumiCalendar, cal2: BangumiCalendar) -> Bool in
      if cal1.id >= weekday && cal2.id < weekday {
        return true
      } else if cal1.id < weekday && cal2.id >= weekday {
        return false
      } else {
        return cal1.id < cal2.id
      }
    }
  }

  func refreshCalendar() async {
    let actor = BackgroundActor(container: modelContext.container)
    do {
      let items = try await chii.getCalendar()
      for item in items {
        Logger.subject.info("processing calendar: \(item.weekday.en)")
        let cal = BangumiCalendar(item: item)
        await actor.insert(data: cal)
        for small in item.items {
          let subject = Subject(small: small)
          try await actor.insertIfNeeded(
            data: subject,
            predicate: #Predicate<Subject> {
              $0.id == small.id
            })
        }
      }
      try await actor.save()
    } catch {
      notifier.alert(error: error)
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
        }
      }.refreshable {
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
              ImageView(img: subject.images?.common, width: 80, height: 80)
              Text(subject.name).font(.caption).multilineTextAlignment(.leading).lineLimit(1)
            }
          }.buttonStyle(PlainButtonStyle())
        }
      }
    }
  }
}
