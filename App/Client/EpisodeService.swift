import Foundation

enum EpisodeService {
  static func getEpisode(_ episodeId: Int) async throws -> EpisodeDTO {
    let url = BangumiURL.next(path: "p1/episodes/\(episodeId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let episode: EpisodeDTO = try await APIClient.shared.decodeResponse(data)
    return episode
  }

  static func getEpisodeComments(_ episodeId: Int) async throws -> [CommentDTO] {
    let url = BangumiURL.next(path: "p1/episodes/\(episodeId)/comments")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createEpisodeComment(episodeId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiURL.next(path: "p1/episodes/\(episodeId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func updateEpisodeCollection(
    episodeId: Int, type: EpisodeCollectionType, batch: Bool = false
  ) async throws {
    let url = BangumiURL.next(path: "p1/collections/episodes/\(episodeId)")
    var body: [String: Any] = [:]
    if batch {
      body["batch"] = true
    } else {
      body["type"] = type.rawValue
    }

    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: body, auth: .required)
  }
}
