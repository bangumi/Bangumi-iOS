import Foundation

enum BangumiStickerResources {
  private static let bundleName = "BangumiStickerResources"
  private static let bundleExtension = "bundle"

  private static var bundle: Bundle {
    guard
      let url = Bundle.main.url(forResource: bundleName, withExtension: bundleExtension),
      let bundle = Bundle(url: url)
    else {
      return Bundle.main
    }

    return bundle
  }

  static func path(
    forResource name: String,
    ofType fileExtension: String,
    inDirectory subdirectory: String? = nil
  ) -> String? {
    bundle.path(forResource: name, ofType: fileExtension, inDirectory: subdirectory)
      ?? Bundle.main.path(forResource: name, ofType: fileExtension, inDirectory: subdirectory)
  }

  static func url(
    forResource name: String,
    withExtension fileExtension: String,
    subdirectory: String? = nil
  ) -> URL? {
    bundle.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
      ?? Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
  }
}
