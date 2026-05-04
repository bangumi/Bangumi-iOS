import SwiftUI

struct OpenSourceLicensesView: View {
  private let licenses = OpenSourceLicenseStore.load()

  var body: some View {
    List {
      if licenses.isEmpty {
        Text("No open source license data was found.")
          .foregroundStyle(.secondary)
      } else {
        Section(header: Text("Third-party components used by this app.")) {
          ForEach(licenses) { license in
            NavigationLink {
              OpenSourceLicenseDetailView(license: license)
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                Text(license.name)
                Text(license.license)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
      }
    }
    .navigationTitle("Open Source Licenses")
    .navigationBarTitleDisplayMode(.inline)
  }
}
