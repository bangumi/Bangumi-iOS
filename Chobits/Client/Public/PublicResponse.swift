struct TokenResponse: Codable {
  var accessToken: String
  var expiresIn: UInt
  var tokenType: String
  var refreshToken: String
}

struct SubjectsResponse: Codable {
  var total: Int
  var limit: Int
  var offset: Int
  var data: [SubjectDTOV0]
}
