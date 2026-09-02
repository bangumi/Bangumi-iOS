import SwiftUI

struct OpenSourceLicenseDetailView: View {
  let license: OpenSourceLicense

  var body: some View {
    List {
      Section {
        Group {
          HStack {
            Text("许可")
            Spacer()
            Text(license.license)
              .foregroundStyle(.secondary)
          }

          Link(destination: license.sourceURL) {
            HStack {
              Label("源代码", systemImage: "chevron.left.forwardslash.chevron.right")
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
        .themedListRow()
      }

      Section(header: Text("许可声明")) {
        Text(license.notice)
          .font(.footnote.monospaced())
          .textSelection(.enabled)
          .themedListRow()
      }
    }
    .navigationTitle(license.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}
