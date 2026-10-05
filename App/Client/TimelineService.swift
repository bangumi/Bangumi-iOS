import Foundation
import OSLog

enum TimelineService {
  static func getTimeline(mode: TimelineMode = .friends, limit: Int = 20, until: Int? = nil)
    async throws -> [TimelineDTO]
  {
    let url = BangumiURL.next(path: "p1/timeline")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "mode", value: mode.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
    ]
    if let until {
      queryItems.append(URLQueryItem(name: "until", value: String(until)))
    }
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let resp: [TimelineDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  /// Subscribes to `GET /p1/timeline/-/events` and yields new timeline items as they
  /// arrive. Reconnects with exponential backoff after failures; only `requireLogin`
  /// is terminal. The stream ends when the consuming task is cancelled.
  static func liveEvents(mode: TimelineMode) -> AsyncThrowingStream<TimelineDTO, Error> {
    let url = BangumiURL.next(path: "p1/timeline/-/events")
      .appending(queryItems: [URLQueryItem(name: "mode", value: mode.rawValue)])
    return AsyncThrowingStream { continuation in
      let task = Task {
        var attempt = 0
        while !Task.isCancelled {
          do {
            let payloads = await APIClient.shared.serverSentEventPayloads(url: url)
            for try await payload in payloads {
              guard let data = payload.data(using: .utf8) else { continue }
              guard let event: TimelineEventDTO = try? await APIClient.shared.decodeResponse(data)
              else {
                Logger.api.warning("timeline live event decode failed: \(payload)")
                continue
              }
              switch event.event {
              case "connected":
                attempt = 0
              case "timeline":
                if let timeline = event.timeline {
                  continuation.yield(timeline)
                }
              default:
                continue
              }
            }
          } catch is CancellationError {
            break
          } catch ChiiError.requireLogin {
            continuation.finish(throwing: ChiiError.requireLogin)
            return
          } catch {
            Logger.api.warning("timeline live stream interrupted, reconnecting: \(error)")
          }
          if Task.isCancelled {
            break
          }
          let backoff = min(pow(2.0, Double(attempt)), 30.0)
          attempt += 1
          try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  static func getTimelineReplies(_ id: Int) async throws -> [CommentDTO] {
    let url = BangumiURL.next(path: "p1/timeline/\(id)/replies")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getTimelineItem(_ id: Int) async throws -> TimelineDTO? {
    let exclusiveUpperBound = id == Int.max ? id : id + 1
    return try await getTimeline(
      mode: .all,
      limit: 1,
      until: exclusiveUpperBound
    ).first(where: { $0.id == id })
  }

  static func postTimeline(content: String, token: String) async throws {
    let url = BangumiURL.next(path: "p1/timeline")
    let body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    let data = try await APIClient.shared.request(url: url, method: "POST", body: body)
    let _: IDResponseDTO = try await APIClient.shared.decodeResponse(data)
  }

  static func postTimelineReply(timelineId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiURL.next(path: "p1/timeline/\(timelineId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }
}
