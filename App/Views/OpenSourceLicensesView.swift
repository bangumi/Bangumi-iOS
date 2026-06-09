import SwiftUI

struct OpenSourceLicensesView: View {
  private let licenses = OpenSourceLicenseStore.load()

  var body: some View {
    List {
      if licenses.isEmpty {
        Text("未找到开源许可数据。")
          .foregroundStyle(.secondary)
      } else {
        Section(header: Text("本应用使用的第三方组件")) {
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
    .navigationTitle("开源许可")
    .navigationBarTitleDisplayMode(.inline)
  }
}
