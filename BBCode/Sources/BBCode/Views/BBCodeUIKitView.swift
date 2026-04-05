import SDWebImage
import UIKit

final class BBCodeBlocksContainerView: UIView {
  private let stackView = UIStackView()
  private var widthConstraint: NSLayoutConstraint?
  private var lastRenderID: String?

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

  func update(blocks: [BBCodePreparedBlock], renderID: String? = nil) {
    if let renderID, lastRenderID == renderID {
      return
    }

    lastRenderID = renderID
    stackView.removeAllArrangedSubviews()
    for block in blocks {
      stackView.addArrangedSubview(makeView(for: block))
    }

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
    case .image(let url, let constrainedSize):
      return BBCodeMediaBlockView(url: url, constrainedSize: constrainedSize)
    case .quote(let blocks):
      return BBCodeQuoteBlockView(blocks: blocks)
    case .list(let items):
      return BBCodeListBlockView(items: items)
    }
  }
}

private final class BBCodeTextBlockView: UITextView {
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
  private let baseAttributedText: NSAttributedString
  private var lastMeasuredWidth: CGFloat = 0
  private var animatedSmileyViews: [Int: AnimatedSmileyImageView] = [:]
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
    textContainerInset = .zero
    textContainer.lineFragmentPadding = 0
    linkTextAttributes = [
      .foregroundColor: UIColor(named: "LinkTextColor") ?? UIColor.systemBlue
    ]
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

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let point = touches.first?.location(in: self),
      let maskRange = maskRange(at: point)
    {
      revealMask(maskRange)
      return
    }

    super.touchesEnded(touches, with: event)
  }

  private func applyRenderedText(forceReload: Bool = false, animated: Bool = false) {
    let renderedText = NSMutableAttributedString(attributedString: baseAttributedText)
    renderedText.enumerateAttribute(
      .bbcodeMask,
      in: NSRange(location: 0, length: renderedText.length)
    ) { value, range, _ in
      guard value != nil, !revealedMasks.contains(MaskRangeKey(range)) else {
        return
      }

      renderedText.addAttribute(.foregroundColor, value: hiddenMaskColor, range: range)
      renderedText.addAttribute(.backgroundColor, value: hiddenMaskColor, range: range)
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
      guard let attachment = value as? SmileyTextAttachment, attachment.item.isDynamic else {
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
    for attachment: SmileyTextAttachment,
    key: Int,
    forceReload: Bool
  ) -> AnimatedSmileyImageView {
    let imageView: AnimatedSmileyImageView
    if let existing = animatedSmileyViews[key] {
      imageView = existing
    } else {
      imageView = AnimatedSmileyImageView()
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

  private func frame(for range: NSRange, attachment: SmileyTextAttachment) -> CGRect {
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

  private func revealMask(_ maskRange: MaskRangeKey) {
    guard revealedMasks.insert(maskRange).inserted else {
      return
    }

    applyRenderedText(animated: true)
  }

  private func maskRange(at point: CGPoint) -> MaskRangeKey? {
    guard attributedText.length > 0 else {
      return nil
    }

    let containerPoint = CGPoint(
      x: point.x - textContainerInset.left + contentOffset.x,
      y: point.y - textContainerInset.top + contentOffset.y
    )

    let glyphIndex = layoutManager.glyphIndex(
      for: containerPoint,
      in: textContainer,
      fractionOfDistanceThroughGlyph: nil
    )
    guard glyphIndex < layoutManager.numberOfGlyphs else {
      return nil
    }

    let glyphRect = layoutManager.boundingRect(
      forGlyphRange: NSRange(location: glyphIndex, length: 1),
      in: textContainer
    )
    guard glyphRect.insetBy(dx: -4, dy: -4).contains(containerPoint) else {
      return nil
    }

    let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
    guard characterIndex < attributedText.length else {
      return nil
    }

    var effectiveRange = NSRange(location: 0, length: 0)
    let value = attributedText.attribute(
      .bbcodeMask,
      at: characterIndex,
      longestEffectiveRange: &effectiveRange,
      in: NSRange(location: 0, length: attributedText.length)
    )
    guard value != nil else {
      return nil
    }

    return MaskRangeKey(effectiveRange)
  }
}

private final class AnimatedSmileyImageView: SDAnimatedImageView {
  var resourcePath: String?
}

private final class BBCodeMediaBlockView: UIView {
  private let url: URL
  private let constrainedSize: CGSize?
  private let imageView = SDAnimatedImageView()
  private let widthConstraint: NSLayoutConstraint
  private let heightConstraint: NSLayoutConstraint

  private var sourceSize: CGSize?
  private var lastMeasuredWidth: CGFloat = 0

  init(url: URL, constrainedSize: CGSize?) {
    self.url = url
    self.constrainedSize = constrainedSize

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = false
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.gray

    widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 0)
    heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)

    super.init(frame: .zero)

    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)

    addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      imageView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
      widthConstraint,
      heightConstraint,
    ])

    sourceSize = constrainedSize
    loadImage()
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

  private func loadImage() {
    imageView.sd_setImage(with: url, placeholderImage: nil, options: [.retryFailed]) {
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

  private func updateDisplayedSize(forceLayout: Bool = false) {
    let horizontalInsets = directionalLayoutMargins.leading + directionalLayoutMargins.trailing
    let availableWidth = max(bounds.width - horizontalInsets, 1)
    let size = resolvedDisplaySize(maxWidth: availableWidth)

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
    let fallbackSide = min(maxWidth, 120)
    let sourceSize = sourceSize ?? CGSize(width: fallbackSide, height: fallbackSide)

    let maxDisplayWidth = min(maxWidth, constrainedSize?.width ?? maxWidth)
    let maxDisplayHeight = constrainedSize?.height ?? CGFloat.greatestFiniteMagnitude

    guard sourceSize.width > 0, sourceSize.height > 0 else {
      return CGSize(width: maxDisplayWidth, height: min(maxDisplayWidth, 120))
    }

    let widthRatio = maxDisplayWidth / sourceSize.width
    let heightRatio = maxDisplayHeight / sourceSize.height
    let scale = min(widthRatio, heightRatio, 1)

    return CGSize(
      width: max(1, round(sourceSize.width * scale)),
      height: max(1, round(sourceSize.height * scale))
    )
  }

  private func invalidateAncestorLayout() {
    var currentView: UIView? = self
    while let view = currentView {
      view.invalidateIntrinsicContentSize()
      view.setNeedsLayout()
      currentView = view.superview
    }
  }
}

private final class BBCodeQuoteBlockView: UIView {
  init(blocks: [BBCodePreparedBlock]) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    setContentCompressionResistancePriority(.required, for: .vertical)
    setContentHuggingPriority(.required, for: .vertical)

    let contentView = BBCodeBlocksContainerView()
    contentView.update(blocks: blocks)

    let barView = UIView()
    barView.translatesAutoresizingMaskIntoConstraints = false
    barView.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.35)
    barView.layer.cornerRadius = 1.5

    let stackView = UIStackView(arrangedSubviews: [barView, contentView])
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

    for item in items {
      stackView.addArrangedSubview(BBCodeListItemView(item: item))
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
  init(item: BBCodePreparedListItem) {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)

    let bulletLabel = UILabel()
    bulletLabel.translatesAutoresizingMaskIntoConstraints = false
    bulletLabel.text = "\u{2022}"
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
      bulletLabel.widthAnchor.constraint(equalToConstant: 10),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension UIStackView {
  fileprivate func removeAllArrangedSubviews() {
    let views = arrangedSubviews
    views.forEach { view in
      removeArrangedSubview(view)
      view.removeFromSuperview()
    }
  }
}
