import Foundation

struct NoticeCacheEntry {
  var noticeID: Int
  var unread: Bool
  var createdAt: Int
  var payloadData: Data?
  var updatedAt: Date

  init(_ notice: NoticeDTO) {
    self.noticeID = notice.id
    self.unread = notice.unread
    self.createdAt = notice.createdAt
    self.payloadData = PersistedJSON.encode(notice)
    self.updatedAt = Date()
  }

  var notice: NoticeDTO? {
    guard var notice = PersistedJSON.decode(NoticeDTO.self, from: payloadData) else {
      return nil
    }
    notice.unread = unread
    return notice
  }
}
