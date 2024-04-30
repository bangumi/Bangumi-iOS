//
//  CalendarView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftData
import SwiftUI

struct CalendarView: View {
  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var errorHandling: ErrorHandling
  @Environment(\.modelContext) private var modelContext

  @Query(sort: \BangumiCalendar.id) private var calendars: [BangumiCalendar]

  var sortedCalendars: [BangumiCalendar] {
    let calendar = Calendar.current
    // FIXME: something wrong with weekday for today
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
      errorHandling.handle(message: "Could not get yesterday")
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

  func refreshCalendar() {
    Task.detached {
      do {
        let cals = try await chiiClient.getCalendar()
        await MainActor.run {
          withAnimation {
            for cal in cals {
              modelContext.insert(cal)
            }
          }
        }
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    if calendars.isEmpty {
      ProgressView().onAppear(perform: refreshCalendar)
    } else {
      ScrollView {
        LazyVStack {
          ForEach(sortedCalendars) { calendar in
            CalendarWeekdayView(calendar: calendar).padding(.vertical, 10)
          }
        }
      }.refreshable {
        refreshCalendar()
      }
    }
  }
}

struct CalendarWeekdayView: View {
  let calendar: BangumiCalendar

  // api /calendar returns image in http
  func imageURL(url: String) -> URL? {
    var components = URLComponents(string: url)
    components?.scheme = "https"
    return components?.url
  }

  var body: some View {
    VStack {
      Text(calendar.weekday.cn).font(.title3)
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
      ]) {
        ForEach(calendar.items) { subject in
          NavigationLink(value: subject) {
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
