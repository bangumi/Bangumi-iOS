import SwiftUI
import UIKit

@MainActor
enum ImagePreviewPresenter {
  @discardableResult
  static func present(
    url: URL,
    from presentingView: UIView,
    zoomSourceView: UIView? = nil,
    onDismiss: (() -> Void)? = nil
  ) -> Bool {
    guard
      let presenter = presentingView.nearestViewController?
        .topMostPresentedViewController
    else {
      onDismiss?()
      return false
    }

    let controller = ImagePreviewHostingController(
      rootView: ImagePreviewer(url: url),
      onDismiss: onDismiss
    )
    controller.modalPresentationStyle = .overFullScreen
    controller.view.backgroundColor = .clear

    if #available(iOS 18.0, *), let zoomSourceView {
      controller.preferredTransition = .zoom { [weak zoomSourceView] _ in
        zoomSourceView
      }
    } else {
      controller.modalTransitionStyle = .crossDissolve
    }

    presenter.present(controller, animated: true)
    return true
  }
}

@MainActor
private final class ImagePreviewHostingController: UIHostingController<ImagePreviewer> {
  private var onDismiss: (() -> Void)?

  init(rootView: ImagePreviewer, onDismiss: (() -> Void)?) {
    self.onDismiss = onDismiss
    super.init(rootView: rootView)
  }

  @available(*, unavailable)
  dynamic required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    if isBeingDismissed || presentingViewController == nil {
      finishDismissal()
    }
  }

  private func finishDismissal() {
    onDismiss?()
    onDismiss = nil
  }
}

extension UIView {
  fileprivate var nearestViewController: UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let viewController = current as? UIViewController {
        return viewController
      }
      responder = current.next
    }

    return nil
  }
}

extension UIViewController {
  fileprivate var topMostPresentedViewController: UIViewController {
    presentedViewController?.topMostPresentedViewController ?? self
  }
}
