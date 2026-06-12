import Foundation
import OSLog

enum DiscoveryRepository {
  static func loadCalendar() async throws {
    let db = try await AppContext.shared.getDB()
    let response = try await DiscoveryService.getCalendar()
    for (weekday, items) in response {
      guard let weekday = Int(weekday) else {
        Logger.api.error("invalid weekday: \(weekday)")
        continue
      }
      try await db.saveCalendarItem(weekday: weekday, items: items)
    }
    await db.commit()
  }

  static func loadTrendingSubjects() async throws {
    var tasks: [Task<(SubjectType, PagedDTO<TrendingSubjectDTO>), Error>] = []
    for type in SubjectType.allTypes {
      tasks.append(
        Task {
          let response = try await DiscoveryService.getTrendingSubjects(type: type)
          return (type, response)
        })
    }
    let db = try await AppContext.shared.getDB()
    for task in tasks {
      let (type, response) = try await task.value
      try await db.saveTrendingSubjects(type: type.rawValue, items: response.data)
    }
    await db.commit()
  }
}
