import SwiftUI

struct OpenSourceLicenseDetailView: View {
  let license: OpenSourceLicense

  var body: some View {
    List {
      Section {
        HStack {
          Text("License")
          Spacer()
          Text(license.license)
            .foregroundStyle(.secondary)
        }

        Link(destination: license.sourceURL) {
          HStack {
            Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            Spacer()
            Image(systemName: "arrow.up.right.square")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

      Section(header: Text("Notice")) {
        Text(license.notice)
          .font(.footnote.monospaced())
          .textSelection(.enabled)
      }
    }
    .navigationTitle(license.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}
