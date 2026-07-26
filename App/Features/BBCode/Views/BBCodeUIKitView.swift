import SDWebImage
import SwiftUI
import UIKit

final class BBCodeBlocksContainerView: UIView {
  private let stackView = UIStackView()
  private var widthConstraint: NSLayoutConstraint?
  private var lastRenderID: String?
  private var openURLHandler: ((URL) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear

    stackView.axis = .vertical
    stackView.alignment = .fill
    stackView.distribution = .fill
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func update(
    blocks: [BBCodePreparedBlock],
    renderID: String? = nil,
    openURLHandler: ((URL) -> Void)? = nil
  ) {
    self.openURLHandler = openURLHandler

    if let renderID, lastRenderID == renderID {
      applyOpenURLHandlerToDescendants()
      return
    }

    lastRenderID = renderID
    stackView.bbcodeRemoveAllArrangedSubviews()
    for block in blocks {
      stackView.addArrangedSubview(makeView(for: block))
    }

    applyOpenURLHandlerToDescendants()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  func fittingSize(for width: CGFloat) -> CGSize? {
    guard width.isFinite, width > 0 else {
      return nil
    }

    let constraint: NSLayoutConstraint
    if let widthConstraint {
      constraint = widthConstraint
    } else {
      constraint = widthAnchor.constraint(equalToConstant: width)
      constraint.isActive = true
      widthConstraint = constraint
    }

    constraint.constant = width
    setNeedsLayout()
    layoutIfNeeded()

    let size = systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )

    return CGSize(width: width, height: ceil(size.height))
  }

  private func makeView(for block: BBCodePreparedBlock) -> UIView {
    switch block.payload {
    case .text(let attributedText):
      return BBCodeTextBlockView(attributedText: attributedText)
    case .image(let media):
      return BBCodeMediaBlockView(media: media)
    case .mask(let blocks):
      return BBCodeMaskBlockView(blocks: blocks)
    case .quote(let blocks):
      return BBCodeQuoteBlockView(blocks: blocks)
    case .list(let items):
      return BBCodeListBlockView(items: items)
    }
  }

  private func applyOpenURLHandlerToDescendants() {
    for arrangedSubview in stackView.arrangedSubviews {
      applyOpenURLHandler(to: arrangedSubview)
    }
  }

  private func applyOpenURLHandler(to view: UIView) {
    if let textBlockView = view as? BBCodeTextBlockView {
      textBlockView.openURLHandler = openURLHandler
    }
    if let mediaBlockView = view as? BBCodeMediaBlockView {
      mediaBlockView.openURLHandler = openURLHandler
    }

    for subview in view.subviews {
      applyOpenURLHandler(to: subview)
    }
  }
}

private final class BBCodeTextBlockView: UITextView, UITextViewDelegate {
  private struct MaskRangeKey: Hashable {
    let location: Int
    let length: Int

    init(_ range: NSRange) {
      self.location = range.location
      self.length = range.length
    }

    var range: NSRange {
      NSRange(location: location, length: length)
    }
  }

  private let hiddenMaskColor = UIColor(white: 0.35, alpha: 1)
  private let revealedMaskTextColor = UIColor.white
  private let maskLinkURL = URL(string: "bbcode-mask://toggle")!
  private let baseAttributedText: NSAttributedString
  var openURLHandler: ((URL) -> Void)?
  private var lastMeasuredWidth: CGFloat = 0
  private var animatedSmileyViews: [Int: BBCodeAnimatedSmileyImageView] = [:]
  private var revealedMasks = Set<MaskRangeKey>()

  init(attributedText: NSAttributedString) {
    self.baseAttributedText = attributedText
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)
    super.init(frame: .zero, textContainer: textContainer)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    isEditable = false
    isSelectable = true
    isScrollEnabled = false
    textDragInteraction?.isEnabled = false
    textContainerInset = UIEdgeInsets(
      top: BBCodeLayoutMetrics.textContainerVerticalInset,
      left: 0,
      bottom: BBCodeLayoutMetrics.textContainerVerticalInset,
      right: 0
    )
    textContainer.lineFragmentPadding = 0
    delegate = self
    linkTextAttributes = [:]
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)
    applyRenderedText(forceReload: true)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    let targetWidth = max(bounds.width, 1)
    let targetSize = sizeThatFits(
      CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
    )
    return CGSize(width: UIView.noIntrinsicMetric, height: ceil(targetSize.height))
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateAnimatedSmileyOverlays()

    if abs(bounds.width - lastMeasuredWidth) > 0.5 {
      lastMeasuredWidth = bounds.width
      invalidateIntrinsicContentSize()
    }
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    if window == nil {
      animatedSmileyViews.values.forEach { $0.stopAnimating() }
    } else {
      animatedSmileyViews.values.forEach { $0.startAnimating() }
    }
  }

  private func applyRenderedText(forceReload: Bool = false, animated: Bool = false) {
    let renderedText = NSMutableAttributedString(attributedString: baseAttributedText)
    renderedText.enumerateAttribute(
      .bbcodeMask,
      in: NSRange(location: 0, length: renderedText.length)
    ) { value, range, _ in
      guard value != nil else {
        return
      }

      let maskRange = MaskRangeKey(range)
      let isRevealed = revealedMasks.contains(maskRange)
      renderedText.addAttribute(.backgroundColor, value: hiddenMaskColor, range: range)
      if isRevealed {
        renderedText.addAttribute(.foregroundColor, value: revealedMaskTextColor, range: range)
      } else {
        renderedText.addAttribute(.foregroundColor, value: hiddenMaskColor, range: range)
        hideAttachments(in: range, in: renderedText)
      }
      applyLinks(in: range, isRevealed: isRevealed, to: renderedText)
    }

    if animated {
      UIView.transition(
        with: self,
        duration: 0.18,
        options: [.transitionCrossDissolve, .allowUserInteraction, .beginFromCurrentState]
      ) {
        super.attributedText = renderedText
      }
    } else {
      super.attributedText = renderedText
    }
    updateAnimatedSmileyOverlays(forceReload: forceReload)
  }

  private func applyLinks(
    in range: NSRange,
    isRevealed: Bool,
    to renderedText: NSMutableAttributedString
  ) {
    guard isRevealed else {
      renderedText.addAttribute(.link, value: maskLinkURL, range: range)
      return
    }

    baseAttributedText.enumerateAttribute(.link, in: range) { value, linkRange, _ in
      renderedText.addAttribute(
        .link,
        value: value ?? maskLinkURL,
        range: linkRange
      )
      guard value != nil else {
        return
      }

      baseAttributedText.enumerateAttribute(.foregroundColor, in: linkRange) {
        color, colorRange, _ in
        guard let color else {
          return
        }
        renderedText.addAttribute(.foregroundColor, value: color, range: colorRange)
      }
    }
  }

  private func hideAttachments(in range: NSRange, in renderedText: NSMutableAttributedString) {
    baseAttributedText.enumerateAttribute(.attachment, in: range) { value, attachmentRange, _ in
      guard let attachment = value as? NSTextAttachment else {
        return
      }

      let renderedSize: CGSize
      if let smiley = attachment as? BBCodeSmileyTextAttachment {
        renderedSize = smiley.renderedSize
      } else if let image = attachment as? BBCodeInlineImageTextAttachment {
        renderedSize = image.renderedSize
      } else {
        renderedSize = attachment.bounds.size
      }

      guard renderedSize.width > 0, renderedSize.height > 0 else {
        return
      }

      renderedText.addAttribute(
        .attachment,
        value: BBCodeHiddenTextAttachment(renderedSize: renderedSize),
        range: attachmentRange
      )
    }
  }

  private func updateAnimatedSmileyOverlays(forceReload: Bool = false) {
    guard attributedText.length > 0 else {
      removeAnimatedSmileyViews()
      return
    }

    layoutManager.ensureLayout(for: textContainer)

    var activeKeys = Set<Int>()
    attributedText.enumerateAttribute(
      .attachment,
      in: NSRange(location: 0, length: attributedText.length)
    ) { value, range, _ in
      guard let attachment = value as? BBCodeSmileyTextAttachment, attachment.item.isDynamic else {
        return
      }

      activeKeys.insert(range.location)
      let imageView = animatedSmileyView(
        for: attachment,
        key: range.location,
        forceReload: forceReload
      )
      imageView.frame = frame(for: range, attachment: attachment)
      imageView.isHidden = imageView.frame.isEmpty
    }

    for (key, imageView) in animatedSmileyViews where !activeKeys.contains(key) {
      imageView.removeFromSuperview()
      animatedSmileyViews.removeValue(forKey: key)
    }
  }

  private func animatedSmileyView(
    for attachment: BBCodeSmileyTextAttachment,
    key: Int,
    forceReload: Bool
  ) -> BBCodeAnimatedSmileyImageView {
    let imageView: BBCodeAnimatedSmileyImageView
    if let existing = animatedSmileyViews[key] {
      imageView = existing
    } else {
      imageView = BBCodeAnimatedSmileyImageView()
      imageView.translatesAutoresizingMaskIntoConstraints = true
      imageView.autoresizingMask = []
      imageView.contentMode = .scaleAspectFit
      imageView.clipsToBounds = false
      imageView.isUserInteractionEnabled = false
      imageView.autoPlayAnimatedImage = true
      addSubview(imageView)
      animatedSmileyViews[key] = imageView
    }

    if forceReload || imageView.resourcePath != attachment.resourcePath {
      imageView.resourcePath = attachment.resourcePath
      imageView.sd_setImage(
        with: URL(fileURLWithPath: attachment.resourcePath),
        placeholderImage: attachment.placeholderImage
      ) { _, _, _, _ in
        imageView.startAnimating()
      }
    }

    return imageView
  }

  private func frame(for range: NSRange, attachment: BBCodeSmileyTextAttachment) -> CGRect {
    let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
    guard glyphRange.length > 0 else {
      return .zero
    }

    var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    rect.origin.x += textContainerInset.left - contentOffset.x
    rect.origin.y += textContainerInset.top - contentOffset.y

    rect = rect.insetBy(dx: attachment.horizontalPadding, dy: 0)
    return rect.integral
  }

  private func removeAnimatedSmileyViews() {
    animatedSmileyViews.values.forEach { $0.removeFromSuperview() }
    animatedSmileyViews.removeAll()
  }

  private func toggleMask(_ maskRange: MaskRangeKey) {
    if revealedMasks.contains(maskRange) {
      revealedMasks.remove(maskRange)
    } else {
      revealedMasks.insert(maskRange)
    }

    applyRenderedText(animated: true)
  }

  func textView(
    _ textView: UITextView,
    primaryActionFor textItem: UITextItem,
    defaultAction: UIAction
  ) -> UIAction? {
    guard case .link(let url) = textItem.content else {
      return defaultAction
    }

    if url.scheme == maskLinkURL.scheme {
      var enclosingRange = NSRange()
      guard
        baseAttributedText.attribute(
          .bbcodeMask,
          at: textItem.range.location,
          effectiveRange: &enclosingRange
        ) != nil
      else {
        return defaultAction
      }
      let maskRange = MaskRangeKey(enclosingRange)
      return UIAction { [weak self] _ in
        self?.toggleMask(maskRange)
      }
    }

    guard let openURLHandler else {
      return defaultAction
    }

    return UIAction { _ in
      openURLHandler(url)
    }
  }
}

private final class BBCodeAnimatedSmileyImageView: SDAnimatedImageView {
  var resourcePath: String?
}

private final class BBCodeHiddenTextAttachment: NSTextAttachment {
  private let renderedSize: CGSize

  init(renderedSize: CGSize) {
    self.renderedSize = renderedSize
    super.init(data: nil, ofType: nil)

    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = false
    self.image = UIGraphicsImageRenderer(size: renderedSize, format: format).image { _ in }
    self.bounds = CGRect(origin: .zero, size: renderedSize)
    allowsTextAttachmentView = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func attachmentBounds(
    for attributes: [NSAttributedString.Key: Any],
    location: any NSTextLocation,
    textContainer: NSTextContainer?,
    proposedLineFragment: CGRect,
    position: CGPoint
  ) -> CGRect {
    let font = (attributes[.font] as? UIFont) ?? .systemFont(ofSize: 16)
    return CGRect(
      x: 0,
      y: BBCodeLayoutMetrics.inlineAttachmentVerticalOffset(for: renderedSize.height, font: font),
      width: renderedSize.width,
      height: renderedSize.height
    )
  }
}

private final class BBCodeMediaBlockView: UIView {
  private let media: BBCodePreparedMedia
  private let imageView = SDAnimatedImageView()
  private let widthConstraint: NSLayoutConstraint
  private let heightConstraint: NSLayoutConstraint

  private var sourceSize: CGSize?
  private var lastMeasuredWidth: CGFloat = 0
  private var loadedThumbnailPixelSize: CGSize?
  private var didLoadOriginalImage = false
  var openURLHandler: ((URL) -> Void)?

  init(media: BBCodePreparedMedia) {
    self.media = media

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = media.constrainedSize == nil ? .scaleAspectFit : .scaleToFill
    imageView.clipsToBounds = false
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.gray

    widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 0)
    heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)

    super.init(frame: .zero)

    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    isUserInteractionEnabled = true
    isAccessibilityElement = true
    accessibilityTraits = [.image, .button]
    accessibilityLabel = media.linkURL == nil ? "Preview image" : "Open image link"
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)

    addSubview(imageView)
    var constraints = [
      imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
      widthConstraint,
      heightConstraint,
    ]
    constraints.append(contentsOf: horizontalConstraints(for: media.alignment))
    NSLayoutConstraint.activate(constraints)

    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePreviewTap)))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(
      width: UIView.noIntrinsicMetric,
      height: layoutMargins.top + heightConstraint.constant + layoutMargins.bottom
    )
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if abs(bounds.width - lastMeasuredWidth) > 0.5 {
      lastMeasuredWidth = bounds.width
      updateDisplayedSize()
    }
  }

  private func horizontalConstraints(for alignment: NSTextAlignment) -> [NSLayoutConstraint] {
    switch alignment {
    case .center:
      return [
        imageView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),
        imageView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
        imageView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
      ]
    case .right:
      return [
        imageView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
        imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      ]
    default:
      return [
        imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
        imageView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
      ]
    }
  }

  private func loadImage(thumbnailPixelSize: CGSize) {
    guard shouldLoadImage(for: thumbnailPixelSize) else {
      return
    }

    loadedThumbnailPixelSize = thumbnailPixelSize
    imageView.sd_setImage(
      with: media.url,
      placeholderImage: nil,
      options: [.retryFailed],
      context: [
        .imageThumbnailPixelSize: NSValue(cgSize: thumbnailPixelSize),
        .imagePreserveAspectRatio: true,
      ],
      progress: nil
    ) {
      [weak self] image, _, _, _ in
      guard let self else { return }
      DispatchQueue.main.async {
        if let image {
          self.sourceSize = image.size
        }
        self.updateDisplayedSize(forceLayout: true)
      }
    }
  }

  private func loadOriginalImageIfNeeded() {
    guard !didLoadOriginalImage else {
      return
    }

    didLoadOriginalImage = true
    imageView.sd_setImage(with: media.url, placeholderImage: nil, options: [.retryFailed]) {
      [weak self] image, _, _, _ in
      guard let self else { return }
      DispatchQueue.main.async {
        if let image {
          self.sourceSize = image.size
        }
        self.updateDisplayedSize(forceLayout: true)
      }
    }
  }

  private func shouldLoadImage(for thumbnailPixelSize: CGSize) -> Bool {
    guard thumbnailPixelSize.width > 1, thumbnailPixelSize.height > 1 else {
      return false
    }

    guard let loadedThumbnailPixelSize else {
      return true
    }

    return thumbnailPixelSize.width > loadedThumbnailPixelSize.width * 1.2
      || thumbnailPixelSize.height > loadedThumbnailPixelSize.height * 1.2
  }

  private func updateDisplayedSize(forceLayout: Bool = false) {
    let horizontalInsets = directionalLayoutMargins.leading + directionalLayoutMargins.trailing
    let availableWidth = max(bounds.width - horizontalInsets, 1)
    let size = resolvedDisplaySize(maxWidth: availableWidth)
    if shouldUseThumbnailDecode {
      loadImage(thumbnailPixelSize: thumbnailPixelSize(for: size, maxWidth: availableWidth))
    } else {
      loadOriginalImageIfNeeded()
    }

    if abs(widthConstraint.constant - size.width) > 0.5
      || abs(heightConstraint.constant - size.height) > 0.5
    {
      widthConstraint.constant = size.width
      heightConstraint.constant = size.height
      invalidateIntrinsicContentSize()
      invalidateAncestorLayout()
    }

    if forceLayout {
      setNeedsLayout()
    }
  }

  private func resolvedDisplaySize(maxWidth: CGFloat) -> CGSize {
    let fallbackSide = min(maxWidth, 160)
    let sourceSize = sourceSize ?? CGSize(width: fallbackSide, height: fallbackSide)

    if let constrainedSize = media.constrainedSize {
      let availableScale = min(maxWidth / constrainedSize.width, 1)
      let sourceScale =
        self.sourceSize.map {
          min(
            $0.width / constrainedSize.width,
            $0.height / constrainedSize.height,
            1
          )
        } ?? 1
      let scale = min(availableScale, sourceScale)

      return CGSize(
        width: max(1, round(constrainedSize.width * scale)),
        height: max(1, round(constrainedSize.height * scale))
      )
    }

    guard sourceSize.width > 0, sourceSize.height > 0 else {
      return CGSize(width: maxWidth, height: min(maxWidth, 120))
    }

    let scale = min(maxWidth / sourceSize.width, 1)

    return CGSize(
      width: max(1, round(sourceSize.width * scale)),
      height: max(1, round(sourceSize.height * scale))
    )
  }

  private func thumbnailPixelSize(for displaySize: CGSize, maxWidth: CGFloat) -> CGSize {
    let scale = window?.screen.scale ?? UIScreen.main.scale
    let targetSize: CGSize
    if sourceSize == nil {
      let maxDisplayWidth = min(maxWidth, media.constrainedSize?.width ?? maxWidth)
      targetSize = CGSize(
        width: maxDisplayWidth,
        height: media.constrainedSize?.height ?? maxDisplayWidth
      )
    } else {
      targetSize = displaySize
    }

    return CGSize(
      width: ceil(targetSize.width * scale),
      height: ceil(targetSize.height * scale)
    )
  }

  private var shouldUseThumbnailDecode: Bool {
    media.constrainedSize != nil || media.url.pathExtension.lowercased() != "svg"
  }

  private func invalidateAncestorLayout() {
    var currentView: UIView? = self
    while let view = currentView {
      view.invalidateIntrinsicContentSize()
      view.setNeedsLayout()
      currentView = view.superview
    }
  }

  @objc private func handlePreviewTap() {
    if let linkURL = media.linkURL, let openURLHandler {
      openURLHandler(linkURL)
      return
    }

    presentPreview()
  }

  private func presentPreview() {
    ImagePreviewPresenter.present(
      url: media.url,
      from: self,
      zoomSourceView: imageView
    )
  }
}

private final class BBCodeMaskBlockView: UIView {
  private let contentView = BBCodeBlocksContainerView()
  private let coverButton = UIButton(type: .custom)

  init(blocks: [BBCodePreparedBlock]) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = UIColor(white: 0.35, alpha: 1)
    layer.cornerRadius = 2
    clipsToBounds = true
    directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 4,
      leading: 5,
      bottom: 4,
      trailing: 5
    )
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)

    contentView.update(blocks: blocks)
    contentView.alpha = 0
    contentView.accessibilityElementsHidden = true

    coverButton.translatesAutoresizingMaskIntoConstraints = false
    coverButton.backgroundColor = .clear
    coverButton.accessibilityLabel = "Reveal hidden content"
    coverButton.addTarget(self, action: #selector(reveal), for: .touchUpInside)

    addSubview(contentView)
    addSubview(coverButton)
    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

      coverButton.topAnchor.constraint(equalTo: topAnchor),
      coverButton.leadingAnchor.constraint(equalTo: leadingAnchor),
      coverButton.trailingAnchor.constraint(equalTo: trailingAnchor),
      coverButton.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func reveal() {
    contentView.accessibilityElementsHidden = false
    UIView.animate(
      withDuration: 0.18,
      animations: {
        self.contentView.alpha = 1
        self.coverButton.alpha = 0
      },
      completion: { _ in
        self.coverButton.isHidden = true
      }
    )
  }
}

private final class BBCodeQuoteBlockView: UIView {
  init(blocks: [BBCodePreparedBlock]) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 0, bottom: 8, trailing: 0)
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)

    let contentView = BBCodeBlocksContainerView()
    contentView.update(blocks: blocks)
    contentView.alpha = 0.56

    let quoteContainer = UIView()
    quoteContainer.translatesAutoresizingMaskIntoConstraints = false
    quoteContainer.backgroundColor = .clear

    let openingQuoteLabel = UILabel()
    openingQuoteLabel.translatesAutoresizingMaskIntoConstraints = false
    openingQuoteLabel.text = "\u{201C}"
    openingQuoteLabel.textColor = UIColor.tertiaryLabel
    openingQuoteLabel.font = .systemFont(ofSize: 18, weight: .medium)

    let closingQuoteLabel = UILabel()
    closingQuoteLabel.translatesAutoresizingMaskIntoConstraints = false
    closingQuoteLabel.text = "\u{201D}"
    closingQuoteLabel.textAlignment = .right
    closingQuoteLabel.textColor = UIColor.tertiaryLabel
    closingQuoteLabel.font = .systemFont(ofSize: 18, weight: .medium)

    quoteContainer.addSubview(openingQuoteLabel)
    quoteContainer.addSubview(contentView)
    quoteContainer.addSubview(closingQuoteLabel)
    NSLayoutConstraint.activate([
      openingQuoteLabel.topAnchor.constraint(equalTo: quoteContainer.topAnchor, constant: -1),
      openingQuoteLabel.leadingAnchor.constraint(equalTo: quoteContainer.leadingAnchor),
      openingQuoteLabel.widthAnchor.constraint(equalToConstant: 10),

      contentView.topAnchor.constraint(equalTo: quoteContainer.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: quoteContainer.leadingAnchor, constant: 10),
      contentView.trailingAnchor.constraint(equalTo: quoteContainer.trailingAnchor, constant: -10),
      contentView.bottomAnchor.constraint(equalTo: quoteContainer.bottomAnchor),

      closingQuoteLabel.trailingAnchor.constraint(equalTo: quoteContainer.trailingAnchor),
      closingQuoteLabel.bottomAnchor.constraint(equalTo: quoteContainer.bottomAnchor, constant: 1),
      closingQuoteLabel.widthAnchor.constraint(equalToConstant: 10),
    ])

    let barView = UIView()
    barView.translatesAutoresizingMaskIntoConstraints = false
    barView.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
    barView.layer.cornerRadius = 1.5

    let stackView = UIStackView(arrangedSubviews: [barView, quoteContainer])
    stackView.axis = .horizontal
    stackView.alignment = .top
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
      barView.widthAnchor.constraint(equalToConstant: 3),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class BBCodeListBlockView: UIView {
  init(items: [BBCodePreparedListItem]) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)

    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.alignment = .fill
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    let markerWidths =
      items
      .map {
        ceil($0.marker.size().width)
      }
    let markerWidth = max(10, markerWidths.max() ?? 0)

    for item in items {
      stackView.addArrangedSubview(
        BBCodeListItemView(
          item: item,
          markerWidth: markerWidth
        )
      )
    }

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class BBCodeListItemView: UIView {
  init(item: BBCodePreparedListItem, markerWidth: CGFloat) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)

    let bulletLabel = UILabel()
    bulletLabel.translatesAutoresizingMaskIntoConstraints = false
    bulletLabel.attributedText = item.marker
    bulletLabel.textAlignment = .right
    bulletLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    bulletLabel.setContentHuggingPriority(.required, for: .horizontal)

    let contentView = BBCodeBlocksContainerView()
    contentView.update(blocks: item.blocks)

    let stackView = UIStackView(arrangedSubviews: [bulletLabel, contentView])
    stackView.axis = .horizontal
    stackView.alignment = .top
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
      bulletLabel.widthAnchor.constraint(equalToConstant: markerWidth),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension UIStackView {
  fileprivate func bbcodeRemoveAllArrangedSubviews() {
    let views = arrangedSubviews
    views.forEach { view in
      removeArrangedSubview(view)
      view.removeFromSuperview()
    }
  }
}
