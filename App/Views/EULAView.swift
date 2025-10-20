import SwiftUI

struct EULAView: View {
  @Binding var isPresented: Bool
  @State private var hasAgreed: Bool = false
  let onAgree: (() -> Void)?

  init(isPresented: Binding<Bool>, onAgree: (() -> Void)? = nil) {
    self._isPresented = isPresented
    self.onAgree = onAgree
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text("社区指导原则")
              .font(.largeTitle)
              .fontWeight(.bold)

            Text("生命有限，Bangumi 是一个**纯粹的ACG网络**，只要明确这一点，你完全可以跳过以下内容的阅读")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .padding(.bottom, 8)

          // Bangumi 鼓励
          VStack(alignment: .leading, spacing: 12) {
            Text("/ Bangumi 鼓励")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 8) {
              EULARuleItem(number: "1", text: "鼓励分享、互助和开放；")
              EULARuleItem(number: "2", text: "鼓励宽容和理性地对待不同的看法、喜好和意见；")
              EULARuleItem(number: "3", text: "鼓励尊重他人的隐私和个人空间；")
              EULARuleItem(number: "4", text: "鼓励转载注明原作者及来源；")
              EULARuleItem(number: "5", text: "鼓励精彩原创内容；")
              EULARuleItem(number: "6", text: "鼓励明确、及时的资源分享和点评；")
              EULARuleItem(number: "7", text: "鼓励有始有终的自发福利活动。")
            }
          }

          // Bangumi 不提倡
          VStack(alignment: .leading, spacing: 12) {
            Text("/ Bangumi 不提倡")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 8) {
              EULARuleItem(number: "1", text: "针对种族、国家、民族、宗教、性别、年龄、地缘、性取向、生理特征的歧视和仇恨言论；")
              EULARuleItem(number: "2", text: "不雅词句、人身攻击、故意骚扰和恶意使用；")
              EULARuleItem(number: "3", text: "色情、激进时政、意识形态方面的话题；")
              EULARuleItem(number: "4", text: "使用脑残体等妨碍视觉与心灵的文字；")
              EULARuleItem(number: "5", text: "无授权转载，盗图、盗链、盗资源；")
              EULARuleItem(number: "6", text: "不提倡情绪激动而心灵枯槁的内容；")
              EULARuleItem(number: "7", text: "不提倡转载过期变质内容；")
              EULARuleItem(number: "8", text: "不提倡不知所谓的长篇大论；")
              EULARuleItem(number: "9", text: "不提倡调查贴、投票贴、签名贴。")
            }
          }

          // Bangumi 禁止
          VStack(alignment: .leading, spacing: 12) {
            Text("/ Bangumi 禁止")
              .font(.title2)
              .fontWeight(.semibold)
              .foregroundColor(.red)

            Text("以下行为视情况**直接删除、锁定或删除ID、批量删除而不予通知**；")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
              EULARuleItem(number: "1", text: "违反中国或 Bangumi 成员所在地法律法规的行为和内容（政策法规）；")
              EULARuleItem(number: "2", text: "威胁他人或 Bangumi 成员自身的人身安全、法律安全的行为；")
              EULARuleItem(number: "3", text: "对网站的运营安全有潜在威胁的内容。")
            }
          }
        }
        .padding()
      }
      .navigationTitle("用户协议")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            isPresented = false
          }
          label: {
            Label("取消", systemImage: "xmark")
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        VStack(spacing: 12) {
          Toggle("我已阅读并同意以上社区指导原则", isOn: $hasAgreed)
            .toggleStyle(.switch)
            .padding(.horizontal)

          Button {
            isPresented = false
            onAgree?()
          } label: {
            Text("同意并继续登录")
              .frame(maxWidth: .infinity)
              .padding()
              .background(hasAgreed ? Color.accentColor : Color.gray)
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          .disabled(!hasAgreed)
          .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
      }
    }
  }
}

struct EULARuleItem: View {
  let number: String
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Text(number)
        .font(.system(.body, design: .monospaced))
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .frame(width: 20, alignment: .leading)

      Text(text)
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

#Preview {
  EULAView(isPresented: .constant(true))
}
