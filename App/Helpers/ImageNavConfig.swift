import SwiftUI

// MARK: - Zoom Navigation ID

/// Unique identifier for zoom navigation source/destination matching
struct ZoomNavigationID: Hashable {
  let type: ZoomNavigationType
  let id: Int

  enum ZoomNavigationType: String {
    case subject
    case character
    case person
  }
}

// MARK: - Environment Key for Shared Namespace

private struct ZoomNamespaceKey: EnvironmentKey {
  static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
  var zoomNamespace: Namespace.ID? {
    get { self[ZoomNamespaceKey.self] }
    set { self[ZoomNamespaceKey.self] = newValue }
  }
}

// MARK: - Shared Namespace Provider

/// Provides a shared namespace for zoom transitions within a NavigationStack
struct ZoomTransitionContainer<Content: View>: View {
  @Namespace private var namespace
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .environment(\.zoomNamespace, namespace)
  }
}

// MARK: - imageNavLink Modifier

@available(iOS 18.0, *)
private struct ImageNavLinkModifier: ViewModifier {
  let link: String?

  @Environment(\.zoomNamespace) private var namespace

  func body(content: Content) -> some View {
    if let link = link,
      let url = URL(string: link),
      let (destination, zoomID) = parseChiiLink(url)
    {
      if let namespace = namespace {
        NavigationLink(value: destination) {
          content
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: zoomID, in: namespace)
      } else {
        NavigationLink(value: destination) {
          content
        }
        .buttonStyle(.plain)
      }
    } else if let link = link, let url = URL(string: link) {
      Link(destination: url) {
        content
      }.buttonStyle(.plain)
    } else {
      content
    }
  }

  private func parseChiiLink(_ url: URL) -> (NavDestination, ZoomNavigationID)? {
    guard url.scheme == "chii" else { return nil }

    let components = url.pathComponents.dropFirst()
    switch url.host {
    case "subject":
      if let idStr = components.first, let id = Int(idStr) {
        return (.subject(id), ZoomNavigationID(type: .subject, id: id))
      }
    case "character":
      if let idStr = components.first, let id = Int(idStr) {
        return (.character(id), ZoomNavigationID(type: .character, id: id))
      }
    case "person":
      if let idStr = components.first, let id = Int(idStr) {
        return (.person(id), ZoomNavigationID(type: .person, id: id))
      }
    default:
      break
    }
    return nil
  }
}

// MARK: - View Extension

extension View {
  /// NavigationLink-based image navigation with iOS 18+ zoom transition support.
  /// Falls back to regular Link on older iOS versions.
  @ViewBuilder
  func imageNavLink(_ link: String?) -> some View {
    if #available(iOS 18.0, *) {
      self.modifier(ImageNavLinkModifier(link: link))
    } else {
      self.imageLink(link)
    }
  }
}

// MARK: - Zoom Transition Modifier for Destination Views

/// Applies navigationTransition(.zoom) to destination views on iOS 18+
struct ZoomTransitionModifier: ViewModifier {
  let zoomID: ZoomNavigationID

  @Environment(\.zoomNamespace) private var namespace

  func body(content: Content) -> some View {
    if #available(iOS 18.0, *), let namespace = namespace {
      content
        .navigationTransition(.zoom(sourceID: zoomID, in: namespace))
    } else {
      content
    }
  }
}
