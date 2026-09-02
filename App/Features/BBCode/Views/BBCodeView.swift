import SwiftUI

public struct BBCodeView: View {
  let code: String
  let textSize: Int

  @Environment(\.bangumiDomains) private var domains
  @Environment(\.openURL) private var openURL
  @Environment(\.theme) private var theme
  @State private var document: BBCodePreparedDocument?

  public init(_ code: String, textSize: Int = 16) {
    self.code = code
    self.textSize = textSize
  }

  public var body: some View {
    Group {
      if let document {
        BBCodeDocumentView(
          document: document,
          renderID: renderID,
          openURLHandler: { url in
            openURL(url)
          }
        )
      } else {
        Text(code)
          .font(.system(size: CGFloat(textSize)))
      }
    }
    .task(id: renderID) {
      document = await BBCode().preparedDocument(
        code,
        textSize: textSize,
        domains: domains,
        palette: theme.bbcodePalette
      )
    }
  }

  private var renderID: String {
    "\(domains.cacheKey)|\(textSize)|\(theme.kind.rawValue)|\(code)"
  }
}

struct BBCodeDocumentView: UIViewRepresentable {
  let document: BBCodePreparedDocument
  let renderID: String
  let openURLHandler: (URL) -> Void

  func makeUIView(context: Context) -> BBCodeBlocksContainerView {
    let view = BBCodeBlocksContainerView()
    view.update(
      blocks: document.blocks,
      palette: document.palette,
      renderID: renderID,
      openURLHandler: openURLHandler
    )
    return view
  }

  func updateUIView(_ uiView: BBCodeBlocksContainerView, context: Context) {
    uiView.update(
      blocks: document.blocks,
      palette: document.palette,
      renderID: renderID,
      openURLHandler: openURLHandler
    )
  }

  func sizeThatFits(
    _ proposal: ProposedViewSize, uiView: BBCodeBlocksContainerView, context: Context
  )
    -> CGSize?
  {
    guard let width = proposal.width, width.isFinite, width > 0 else {
      return nil
    }

    return uiView.fittingSize(for: width)
  }
}
