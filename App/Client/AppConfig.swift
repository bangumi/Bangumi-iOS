import Foundation

enum AppConfig {
  static nonisolated var isAuthenticated: Bool {
    get { UserDefaults.standard.bool(forKey: "isAuthenticated") }
    set { UserDefaults.standard.set(newValue, forKey: "isAuthenticated") }
  }

  static nonisolated var authDomain: AuthDomain {
    get {
      let value = UserDefaults.standard.string(forKey: "authDomain")
      return AuthDomain(rawValue: value ?? AuthDomain.next.rawValue) ?? .next
    }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: "authDomain") }
  }

  static nonisolated var collectionsUpdatedAt: Int {
    get { UserDefaults.standard.integer(forKey: "collectionsUpdatedAt") }
    set { UserDefaults.standard.set(newValue, forKey: "collectionsUpdatedAt") }
  }

  static nonisolated var profile: String {
    get { UserDefaults.standard.string(forKey: "profile") ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: "profile") }
  }

  static nonisolated var userAgent: String {
    get { UserDefaults.standard.string(forKey: "userAgent") ?? "" }
    set { UserDefaults.standard.set(newValue, forKey: "userAgent") }
  }

  static nonisolated var subjectCollectsFilterMode: FilterMode {
    get { FilterMode(UserDefaults.standard.string(forKey: "subjectCollectsFilterMode")) }
    set { UserDefaults.standard.set(newValue.rawValue, forKey: "subjectCollectsFilterMode") }
  }
}
