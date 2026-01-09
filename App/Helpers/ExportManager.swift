import Foundation
import SwiftData

struct ExportManager {

  static func exportSubjects(
    subjects: [Subject],
    fields: Set<ExportableField>,
    coverSize: CoverExportSize = .r400
  ) -> URL? {
    let sortedFields = ExportableField.allCases.filter { fields.contains($0) }

    var csvContent = ""

    // Header row
    let headers = sortedFields.map { $0.label }
    csvContent += headers.joined(separator: ",") + "\n"

    // Data rows
    for subject in subjects {
      let values = sortedFields.map { field -> String in
        let value = field.value(from: subject, coverSize: coverSize)
        // Escape CSV special characters
        return escapeCSV(value)
      }
      csvContent += values.joined(separator: ",") + "\n"
    }

    // Save to file
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    let timestamp = dateFormatter.string(from: Date())
    let filename = "bangumi_export_\(timestamp).csv"

    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent(filename)

    do {
      // Use UTF-8 with BOM for Excel compatibility
      let bom = "\u{FEFF}"
      try (bom + csvContent).write(to: fileURL, atomically: true, encoding: .utf8)
      return fileURL
    } catch {
      return nil
    }
  }

  private static func escapeCSV(_ value: String) -> String {
    // If value contains comma, quote, or newline, wrap in quotes and escape quotes
    if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
      let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return value
  }
}
