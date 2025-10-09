import SwiftUI

@available(iOS 18.0, *)
struct ChiiTestView: View {
  @State private var content: String = ""
  @State private var show: Bool = false
  @State private var textSelection: TextSelection? = nil

  var body: some View {
    VStack {
      Button("测试") {
        show = true
      }
      BorderView {
        TextEditor(text: $content, selection: $textSelection)
          .frame(height: 200)
      }
    }
    .sheet(isPresented: $show) {
      ScrollView {
        VStack {
          Text("测试 sheet")
            .font(.headline)
          BorderView {
            TextEditor(text: $content, selection: $textSelection)
              .frame(height: 200)
          }
        }.padding()
      }
    }
  }
}
