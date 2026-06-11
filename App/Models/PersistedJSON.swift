import Foundation

enum PersistedJSON {
  static func encode<Value: Encodable>(_ value: Value) -> Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try? encoder.encode(value)
  }

  static func decode<Value: Decodable>(_ type: Value.Type, from data: Data?) -> Value? {
    guard let data else {
      return nil
    }
    return try? JSONDecoder().decode(type, from: data)
  }
}
