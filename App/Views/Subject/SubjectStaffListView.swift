import Flow
import SwiftData
import SwiftUI

struct SubjectStaffListView: View {
  let subjectId: Int

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectStaffDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectStaffPersons(
        subjectId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SubjectStaffDTO, _>(limit: 20, nextPageFunc: load) { item in
        CardView {
          HStack {
            ImageView(img: item.staff.images?.medium)
              .imageStyle(width: 60, height: 60, alignment: .top)
              .imageType(.person)
              .imageNavLink(item.staff.link)
            VStack(alignment: .leading) {
              Text(item.staff.name.withLink(item.staff.link))
                .font(.callout)
                .lineLimit(1)
              Text(item.staff.nameCN)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
              HFlow {
                ForEach(item.positions) { position in
                  if !position.type.cn.isEmpty {
                    HStack {
                      BorderView {
                        Text(position.type.cn)
                      }
                    }
                  }
                }
              }
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            }.padding(.leading, 4)
            Spacer()
          }
        }
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("制作人员")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "person.2").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let subject = Subject.previewAnime
  return SubjectStaffListView(subjectId: subject.subjectId)
}
