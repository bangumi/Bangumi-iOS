import SwiftUI

public struct BBCodeView: View {
  let code: String
  let textSize: Int
  @State private var rendered: TextView?

  public init(_ code: String, textSize: Int = 16) {
    self.code = code
    self.textSize = textSize
  }

  public var body: some View {
    let font = Font.system(size: CGFloat(textSize))

    Group {
      if let rendered = rendered {
        switch rendered {
        case .string(let content):
          Text(content)
            .font(font)
        case .text(let content):
          content
            .font(font)
        case .view(let content):
          content
            .font(font)
        }
      } else {
        Text(code)
          .font(font)
      }
    }
    .task(id: "\(textSize)|\(code)") {
      rendered = BBCode().text(code, args: ["textSize": textSize])
    }
  }
}

#Preview {
  let example = """
    [img]https://freeimage.host/i/JwFUoRp[/img]
    我是[b]粗体字[/b]
    我是[i]斜体字[/i]
    我是[u]下划线文字[/u]
    我是[s]删除线文字[/s]
    [center]居中文字[/center]
    [left]居左文字[/left]
    [right]居右文字[/right]
    我是[mask]马赛克文字[/mask]
    我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]
    [size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现
    Bangumi 番组计划: [url]https://chii.in/[/url]
    带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]
    存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]
    调整图片大小[img=60,40]https://chii.in/img/ico/bgm88-31.gif[/img]
    [img=600,400]https://chii.in/img/ico/bgm88-31.gif[/img]

    [img]https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/2.gif[/img]
    [img]https://static.hya.moe/execwb-publish/bgm-publish-heading.webp[/img]
    [img]https://static.hya.moe/execwb-demo.avif[/img]
    [img]https://static.hya.moe/execwb-demo.mp4[/img]
    [img]https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/svg2009.svg[/img]

    代码片段：
    [code]
    print("Hello, World!")
    exit(0)
    [/code]
    (bgm38) (bgm24)
    (bmoCAoAEghP8A4BNgiKWBA) 紫色的
    绿色的 (bmoCArACghOkAoBNgiKGAg)
    [quote]引用的片段[/quote]
    [photo=104569]4b/d1/873244_3p4I7.jpg[/photo]
    [subject=12]ちぃでかける[/subject]
    [user=873244]五月雨[/user]

    传说中性能超强的人型电脑，故事第一话时被人弃置在垃圾场，[i]后被我们的本须和秀树发现，[s]并抱[u]回家[/u][/s][/i]。[color=red]由于开始时唧只会[b]'唧，唧'[/b]的这样叫[/color]，所以秀树为其取名 '唧' [mask]TV版第二话「[s]ちぃでかける[/s]」[/mask]时发现小唧本身并没有安OS，不过因为拥有“学习程式”，所以可以通过对话和教导让她‘成长’起来 (bgm38)。

    ruby测试1：[ruby=あさ]朝[/ruby]ruby测试2:[ruby=a i u e o]あいうえお[/ruby]
    「诶。那就[ruby=ナンジャモンジャ]怪物指名[/ruby]，[ruby=ゾンかまパ—ティ—]僵尸感染派对[/ruby]和UNO吧。」（注：这几个游戏的平均游戏时长都在10分钟之内。）

    """
  ScrollView {
    Divider()
    BBCodeView(example).padding()
    Divider()
  }
}
