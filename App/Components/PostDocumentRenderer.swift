import Foundation

struct PostWebDocument: Equatable, Sendable {
  let id: UUID
  let html: String
  let baseURL: URL
  let initialPostID: Int?
}

struct PostDocumentRenderInput: Hashable, Sendable {
  struct Parent: Hashable, Sendable {
    let title: String
    let link: String
    let iconURL: String?
    let badge: String
  }

  struct User: Hashable, Sendable {
    let id: Int
    let name: String
    let sign: String?
    let link: String?
    let avatarURL: String?
    let isPoster: Bool
    let isFriend: Bool
    let anonymousColor: String?
  }

  struct Reaction: Hashable, Sendable {
    let value: Int
    let count: Int
    let selected: Bool
    let smileyCode: String
  }

  struct Post: Hashable, Sendable {
    let id: Int
    let floor: String
    let createdAt: String
    let content: String
    let user: User
    let isNormal: Bool
    let stateDescription: String
    let isBlocked: Bool
    let reactions: [Reaction]
    let replies: [Post]
  }

  struct MainActions: Hashable, Sendable {
    let replyCount: Int
    let showsIndex: Bool
    let showsReaction: Bool
  }

  let baseURL: URL
  let domains: BangumiDomains
  let parent: Parent?
  let title: String?
  let mainPost: Post?
  let mainActions: MainActions?
  let replies: [Post]
  let emptyMessage: String
  let canReply: Bool
  let canReact: Bool
  let showReactions: Bool
  let avatarIsRound: Bool
  let initialPostID: Int?
}

actor PostDocumentRenderer {
  static let shared = PostDocumentRenderer()
  static let stickerURLScheme = "bangumi-sticker"

  func render(_ input: PostDocumentRenderInput) throws -> PostWebDocument {
    try Task.checkCancellation()
    let body = try renderBody(input)
    try Task.checkCancellation()
    let html = """
      <!doctype html>
      <html lang="zh-Hans">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
        <style>
          :root {
            color-scheme: light dark;
            --background: #ffffff;
            --row-alternate: #f9f9f9;
            --primary: #1c1c1e;
            --secondary: #6c6c70;
            --tertiary: #8e8e93;
            --separator: rgba(60, 60, 67, 0.18);
            --control: rgba(118, 118, 128, 0.12);
            --reaction-background: #fefefe;
            --avatar-border: rgba(28, 28, 30, 0.15);
            --link: #0084b4;
            --accent: #0084b4;
          }

          @media (prefers-color-scheme: dark) {
            :root {
              --background: #000000;
              --row-alternate: #1c1c1e;
              --primary: #f2f2f7;
              --secondary: #aeaeb2;
              --tertiary: #8e8e93;
              --separator: rgba(84, 84, 88, 0.65);
              --control: rgba(118, 118, 128, 0.24);
              --reaction-background: rgba(255, 255, 255, 0.05);
              --avatar-border: rgba(242, 242, 247, 0.15);
            }
          }

          * {
            box-sizing: border-box;
          }

          html {
            min-height: 100%;
            background: var(--background);
            -webkit-text-size-adjust: 100%;
          }

          body {
            margin: 0;
            min-height: 100vh;
            min-height: 100dvh;
            padding: 0 0 calc(20px + env(safe-area-inset-bottom));
            background: var(--background);
            color: var(--primary);
            font: -apple-system-body;
            overflow-wrap: anywhere;
          }

          a {
            color: var(--link);
            text-decoration: none;
          }

          button,
          input {
            font: inherit;
          }

          button {
            -webkit-appearance: none;
            appearance: none;
          }

          .topic-card {
            margin: 8px 8px 2px;
            padding: 8px;
            border: 1px solid var(--separator);
            border-radius: 12px;
            background: var(--background);
          }

          .main-post {
            padding: 10px 12px 12px;
            border-bottom: 1px solid var(--separator);
          }

          .parent {
            display: flex;
            align-items: center;
            gap: 5px;
            min-width: 0;
            color: var(--primary);
            font-size: 0.78em;
          }

          .parent-title {
            flex: 1;
            min-width: 0;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }

          .parent-icon {
            width: 28px;
            height: 28px;
            flex: 0 0 auto;
            border-radius: 4px;
            object-fit: cover;
          }

          .parent-badge,
          .badge {
            display: inline-flex;
            align-items: center;
            flex: 0 0 auto;
            border: 1px solid var(--separator);
            color: var(--secondary);
          }

          .parent-badge {
            border-radius: 5px;
            padding: 2px 5px;
            font-size: 0.72em;
          }

          .badge {
            border-radius: 4px;
            min-height: 19px;
            padding: 2px 5px 3px;
            font-size: 0.68em;
            line-height: 1;
          }

          .topic-title {
            margin: 5px 0 0;
            padding-top: 5px;
            border-top: 1px solid var(--separator);
            font-size: 1.1em;
            line-height: 1.3;
          }

          .reply {
            padding: 12px;
            border-bottom: 1px dashed var(--separator);
            content-visibility: auto;
            contain-intrinsic-size: auto 220px;
          }

          main > .reply:nth-child(even) {
            background: var(--row-alternate);
          }

          .post-header {
            display: flex;
            align-items: flex-start;
            gap: 8px;
          }

          .avatar {
            width: 40px;
            height: 40px;
            flex: 0 0 auto;
            border: 0.5px solid var(--avatar-border);
            border-radius: \(input.avatarIsRound ? "50%" : "5px");
            object-fit: cover;
          }

          .post-heading {
            flex: 1;
            min-width: 0;
          }

          .user-line {
            display: flex;
            align-items: center;
            gap: 4px;
            min-width: 0;
          }

          .user-identity {
            flex: 1;
            min-width: 0;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }

          .user-sign {
            color: var(--secondary);
            font-size: 0.78em;
          }

          .timestamp {
            margin-top: 1px;
            color: var(--secondary);
            font-size: 0.76em;
            white-space: nowrap;
          }

          .post-actions {
            display: flex;
            align-items: center;
            flex: 0 0 auto;
            gap: 3px;
          }

          .main-actions {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 6px;
            margin-top: 7px;
            margin-left: 56px;
          }

          .action {
            display: inline-flex;
            align-items: center;
            gap: 3px;
            min-height: 28px;
            border: 1px solid var(--separator);
            border-radius: 14px;
            padding: 4px 9px;
            background: transparent;
            color: var(--secondary);
            font-size: 0.78em;
            line-height: 1;
            white-space: nowrap;
          }

          .button-icon {
            display: block;
            flex: 0 0 auto;
          }

          .icon-action {
            display: grid;
            width: 26px;
            height: 26px;
            min-height: 26px;
            place-items: center;
            border: 0;
            border-radius: 7px;
            padding: 0;
            background: transparent;
            color: var(--tertiary);
          }

          .icon-action svg {
            display: block;
            width: 14px;
            height: 14px;
          }

          .action:active {
            background: color-mix(in srgb, var(--control) 75%, var(--separator));
            color: var(--link);
          }

          .action:disabled {
            opacity: 0.4;
          }

          .post-content {
            margin: 5px 0 0 48px;
            line-height: 1.35;
          }

          .post-content p {
            margin: 0.35em 0;
          }

          .post-content img {
            display: block;
            width: auto;
            max-width: 100%;
            height: auto;
            margin: 6px 0;
          }

          .post-content .bbcode-align-center img {
            margin-inline: auto;
          }

          .post-content .bbcode-align-right img {
            margin-inline-start: auto;
            margin-inline-end: 0;
          }

          .post-content img.smile,
          .post-content img.bmo-emoji,
          .post-content img.smile-dynamic,
          .post-content img.smile-musume,
          .post-content img.smile-blake {
            display: inline-block;
            margin: 0;
            vertical-align: bottom;
          }

          .post-content img.smile {
            image-rendering: pixelated;
          }

          .post-content img.smile-dynamic {
            max-width: 55px;
            max-height: 55px;
            image-rendering: auto;
          }

          .main-content .avatar {
            width: 48px;
            height: 48px;
          }

          .main-content .post-content,
          .main-content .reactions {
            margin-left: 56px;
          }

          .post-content pre {
            max-width: 100%;
            overflow-x: auto;
            border: 1px solid var(--separator);
            border-radius: 8px;
            padding: 10px;
            background: var(--control);
            white-space: pre-wrap;
          }

          .post-content blockquote {
            margin: 6px 0;
            padding-left: 12px;
            border-left: 3px solid var(--separator);
            color: var(--secondary);
          }

          .mask {
            border: 1px solid #555;
            border-radius: 2px;
            background: #555;
            color: #555;
            padding: 0 5px;
            position: relative;
          }

          .mask > .inner {
            opacity: 0;
            transition: opacity 0.18s linear;
          }

          .mask a {
            color: #555 !important;
          }

          .mask.revealed {
            color: #fff !important;
          }

          .mask.revealed > .inner {
            opacity: 1;
            position: relative;
          }

          .mask.revealed a {
            color: var(--link) !important;
          }

          .reactions {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 3px;
            margin: 5px 0 0 48px;
            opacity: 0.7;
          }

          .reaction {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 5px;
            border: 0;
            border-radius: 10px;
            padding: 2px 5px 3px 8px;
            background: var(--reaction-background);
            color: #f09199;
            box-shadow: 0 0 3px rgba(0, 0, 0, 0.1);
            line-height: 1;
          }

          .reaction.selected {
            box-shadow: 0 0 2px var(--link);
          }

          .reaction img {
            width: 18px;
            height: 18px;
            flex: 0 0 auto;
            object-fit: contain;
          }

          .reaction span {
            padding: 2px 2px 0 0;
            color: var(--secondary);
            font-size: 11px;
          }

          .reaction.selected span {
            color: var(--link);
          }

          .subreplies {
            margin: 8px 0 0 48px;
            border-top: 1px dashed var(--separator);
          }

          .subreplies .reply {
            padding-left: 0;
            padding-right: 0;
          }

          .subreplies > .reply:last-child {
            border-bottom: 0;
          }

          .subreplies .post-content,
          .subreplies .reactions {
            margin-left: 48px;
          }

          .state,
          .blocked {
            margin: 8px 0;
            padding: 8px 10px;
            border-radius: 7px;
            color: var(--secondary);
            background: var(--control);
            font-size: 0.84em;
          }

          .blocked {
            height: 8px;
            padding: 0;
            background: linear-gradient(90deg, var(--secondary), transparent);
          }

          .topic-footer {
            display: flex;
            justify-content: center;
            height: 91px;
            margin: 0;
            padding-top: 16px;
            overflow: hidden;
          }

          .topic-musume {
            width: 39px;
            height: 75px;
            overflow: hidden;
          }

          .topic-musume img {
            display: block;
            width: 280px;
            height: 75px;
            max-width: none;
            transform: translateX(-120px);
          }

        </style>
      </head>
      <body>
        \(body)
        <script>
          (() => {
            const bridge = window.webkit?.messageHandlers?.postAction;
            const post = (payload) => bridge?.postMessage(payload);

            document.addEventListener('click', (event) => {
              const action = event.target.closest('[data-action]');
              if (action) {
                event.preventDefault();
                if (action.disabled) return;

                const payload = { action: action.dataset.action };
                if (action.dataset.postId) payload.postId = Number(action.dataset.postId);
                if (action.dataset.value) payload.value = Number(action.dataset.value);
                if (
                  action.dataset.action === 'reactionPicker' ||
                  action.dataset.action === 'more'
                ) {
                  const rect = action.getBoundingClientRect();
                  payload.anchorY = (rect.top + rect.height / 2) / window.innerHeight;
                }
                post(payload);
                return;
              }

              const mask = event.target.closest('.mask');
              if (mask) {
                if (!mask.classList.contains('revealed')) {
                  event.preventDefault();
                  mask.classList.add('revealed');
                  return;
                }

                if (!event.target.closest('a')) {
                  event.preventDefault();
                  mask.classList.remove('revealed');
                  return;
                }
              }

              const image = event.target.closest('.post-content img');
              if (
                image &&
                !image.closest('a') &&
                !image.classList.contains('smile') &&
                !image.classList.contains('smile-dynamic') &&
                !image.classList.contains('smile-musume') &&
                !image.classList.contains('smile-blake') &&
                !image.currentSrc.startsWith('data:')
              ) {
                event.preventDefault();
                post({ action: 'previewImage', url: image.currentSrc });
              }
            });

            document.addEventListener('contextmenu', (event) => {
              const reaction = event.target.closest('.reaction');
              if (!reaction) return;

              event.preventDefault();
              post({
                action: 'reactionUsers',
                postId: Number(reaction.dataset.postId),
                value: Number(reaction.dataset.value),
              });
            });

            document.querySelectorAll('.post-content img').forEach((image) => {
              const requestedWidth = Number(image.getAttribute('width'));
              const requestedHeight = Number(image.getAttribute('height'));

              if (image.classList.contains('smile-dynamic')) {
                image.style.width = 'auto';
                image.style.height = 'auto';
                image.style.maxWidth = '55px';
                image.style.maxHeight = '55px';
                return;
              }

              if (image.classList.contains('smile') || image.src.startsWith('data:')) {
                return;
              }

              image.style.width = 'auto';
              image.style.height = 'auto';
              image.style.maxWidth =
                requestedWidth > 0 ? `min(100%, ${requestedWidth}px)` : '100%';
              if (requestedHeight > 0) {
                image.style.maxHeight = `${requestedHeight}px`;
              }
            });
          })();
        </script>
      </body>
      </html>
      """

    try Task.checkCancellation()
    return PostWebDocument(
      id: UUID(),
      html: html,
      baseURL: input.baseURL,
      initialPostID: input.initialPostID
    )
  }

  private func renderBody(_ input: PostDocumentRenderInput) throws -> String {
    try Task.checkCancellation()
    let documentHeader: String
    if let parent = input.parent, let title = input.title {
      let parentIcon =
        parent.iconURL.map {
          "<img class=\"parent-icon\" src=\"\($0.bbcodeHTMLEscaped)\" alt=\"\" loading=\"lazy\">"
        } ?? ""
      documentHeader = """
        <header class="topic-card">
          <a class="parent" href="\(parent.link.bbcodeHTMLEscaped)">
            \(parentIcon)
            <span class="parent-title">\(parent.title.bbcodeHTMLEscaped)</span>
            <span class="parent-badge">\(parent.badge.bbcodeHTMLEscaped)</span>
          </a>
          <h1 class="topic-title">\(title.bbcodeHTMLEscaped)</h1>
        </header>
        """
    } else {
      documentHeader = ""
    }

    let mainPost: String
    if let post = input.mainPost {
      let renderedPost = try renderPost(post, input: input, isMain: true)
      let actions =
        input.mainActions.map {
          renderMainActions(postID: post.id, actions: $0, input: input)
        } ?? ""
      mainPost = """
        <section class="main-post">
          \(renderedPost)
          \(actions)
        </section>
        """
    } else {
      mainPost = ""
    }

    let replies: String
    if input.replies.isEmpty {
      replies = "<div class=\"state\">\(input.emptyMessage.bbcodeHTMLEscaped)</div>"
    } else {
      var renderedReplies = ""
      for post in input.replies {
        try Task.checkCancellation()
        renderedReplies.append(try renderPost(post, input: input, isMain: false))
      }
      replies = renderedReplies
    }

    try Task.checkCancellation()
    return """
      \(documentHeader)
      \(mainPost)
      <main>
        \(replies)
      </main>
      <footer class="topic-footer" aria-hidden="true">
        <div class="topic-musume">
          <img src="\(Self.stickerURLScheme)://asset/musume.png" alt="">
        </div>
      </footer>
      """
  }

  private func renderPost(
    _ post: PostDocumentRenderInput.Post,
    input: PostDocumentRenderInput,
    isMain: Bool
  ) throws -> String {
    try Task.checkCancellation()
    if post.isBlocked {
      return isMain ? "" : "<article class=\"reply blocked\" id=\"post_\(post.id)\"></article>"
    }

    let articleClass = isMain ? "main-content" : "reply"
    let content: String
    if post.isNormal {
      content = try renderBBCode(post.content, domains: input.domains)
    } else {
      content = "<div class=\"state\">\(post.stateDescription.bbcodeHTMLEscaped)</div>"
    }

    let replies: String
    if post.replies.isEmpty {
      replies = ""
    } else {
      var renderedReplies = ""
      for reply in post.replies {
        try Task.checkCancellation()
        renderedReplies.append(try renderPost(reply, input: input, isMain: false))
      }
      replies = "<div class=\"subreplies\">\(renderedReplies)</div>"
    }

    let reactions =
      post.isNormal ? try renderReactions(post.reactions, postID: post.id, input: input) : ""
    try Task.checkCancellation()

    return """
      <article class="\(articleClass)" id="post_\(post.id)">
        \(renderHeader(post, input: input, isMain: isMain))
        <div class="post-content">\(content)</div>
        \(reactions)
        \(replies)
      </article>
      """
  }

  private func renderHeader(
    _ post: PostDocumentRenderInput.Post,
    input: PostDocumentRenderInput,
    isMain: Bool
  ) -> String {
    let user = post.user
    let avatar: String
    if let anonymousColor = user.anonymousColor {
      avatar =
        "<span class=\"avatar\" style=\"background:\(anonymousColor.bbcodeHTMLEscaped)\"></span>"
    } else if let avatarURL = user.avatarURL {
      avatar =
        "<img class=\"avatar\" src=\"\(avatarURL.bbcodeHTMLEscaped)\" alt=\"\" loading=\"lazy\">"
    } else {
      avatar = "<span class=\"avatar\"></span>"
    }
    let linkedAvatar =
      user.link.map {
        "<a href=\"\($0.bbcodeHTMLEscaped)\">\(avatar)</a>"
      } ?? avatar
    let userName =
      user.link.map {
        "<a class=\"user-name\" href=\"\($0.bbcodeHTMLEscaped)\">\(user.name.bbcodeHTMLEscaped)</a>"
      } ?? "<span class=\"user-name\">\(user.name.bbcodeHTMLEscaped)</span>"
    let userSign =
      user.sign.map {
        "<span class=\"user-sign\"> (\($0.bbcodeHTMLEscaped))</span>"
      } ?? ""
    let badges: String = [
      user.isPoster ? "<span class=\"badge\">楼主</span>" : "",
      user.isFriend ? "<span class=\"badge\">好友</span>" : "",
    ].joined()
    let actions =
      isMain || !post.isNormal ? "" : renderPostActions(postID: post.id, input: input)

    return """
      <header class="post-header">
        \(linkedAvatar)
        <div class="post-heading">
          <div class="user-line">\(badges)<span class="user-identity">\(userName)\(userSign)</span></div>
          <div class="timestamp">\(post.floor.bbcodeHTMLEscaped) · \(post.createdAt.bbcodeHTMLEscaped)</div>
        </div>
        \(actions)
      </header>
      """
  }

  private func renderPostActions(postID: Int, input: PostDocumentRenderInput) -> String {
    let replyDisabled = input.canReply ? "" : " disabled"
    let reactionButton =
      input.showReactions
      ? """
      <button class="action icon-action" data-action="reactionPicker" data-post-id="\(postID)" aria-label="贴贴" title="贴贴"\(input.canReact ? "" : " disabled")>
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8"/></svg>
      </button>
      """
      : ""

    return """
      <div class="post-actions">
        <button class="action icon-action" data-action="reply" data-post-id="\(postID)" aria-label="回复" title="回复"\(replyDisabled)>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9 14-5-5 5-5M4 9h11a5 5 0 0 1 5 5v2" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8"/></svg>
        </button>
        \(reactionButton)
        <button class="action icon-action" data-action="more" data-post-id="\(postID)" aria-label="更多" title="更多">
          <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="5" cy="12" r="1.6" fill="currentColor"/><circle cx="12" cy="12" r="1.6" fill="currentColor"/><circle cx="19" cy="12" r="1.6" fill="currentColor"/></svg>
        </button>
      </div>
      """
  }

  private func renderMainActions(
    postID: Int,
    actions: PostDocumentRenderInput.MainActions,
    input: PostDocumentRenderInput
  ) -> String {
    let replyDisabled = input.canReply ? "" : " disabled"
    let replyIcon = """
      <svg class="button-icon" width="15" height="15" viewBox="0 0 15 15" fill="none" aria-hidden="true">
        <path d="M8 1C11.3084 1 14 3.31809 14 6.16742C14 7.84643 13.072 9.39582 11.5019 10.3658C11.7198 11.4366 12.208 12.188 12.2133 12.1961L12.747 13L11.8213 12.8752C11.7147 12.8608 9.23129 12.5147 7.46123 11.3141C6.00764 11.2028 4.6576 10.6421 3.64894 9.72848C2.58561 8.76527 2 7.50062 2 6.16748C2 3.31809 4.6916 1 8 1Z" fill="#CCCCCC"/>
      </svg>
      """
    let indexIcon = """
      <svg class="button-icon" width="18" height="15" viewBox="0 0 18 15" fill="none" aria-hidden="true">
        <path d="M0 13.6591V2.6979C0 2.62789 0.00540297 2.56327 0.0162089 2.50404C0.0270149 2.4448 0.0540297 2.38018 0.0972535 2.31018C0.340387 1.89553 0.694282 1.51319 1.15894 1.16317C1.629 0.813139 2.1801 0.533118 2.81225 0.323102C3.4498 0.107701 4.14138 0 4.88699 0C5.76767 0 6.57001 0.158858 7.29401 0.476575C8.02341 0.788907 8.59343 1.19548 9.00405 1.69628C9.40927 1.19548 9.97389 0.788907 10.6979 0.476575C11.4273 0.158858 12.235 0 13.1211 0C13.8613 0 14.5475 0.107701 15.1796 0.323102C15.8172 0.533118 16.371 0.813139 16.8411 1.16317C17.3111 1.51319 17.665 1.89553 17.9027 2.31018C17.946 2.38018 17.973 2.4448 17.9838 2.50404C17.9946 2.56327 18 2.62789 18 2.6979V13.6591C18 13.993 17.9081 14.2299 17.7244 14.37C17.5407 14.51 17.33 14.58 17.0923 14.58C16.9518 14.58 16.8167 14.545 16.6871 14.475C16.5574 14.4103 16.4169 14.3296 16.2656 14.2326C15.8172 13.9311 15.3255 13.6914 14.7906 13.5137C14.2611 13.3414 13.7154 13.2579 13.1535 13.2633C12.5646 13.2687 11.9892 13.3791 11.4273 13.5945C10.8708 13.8099 10.3656 14.1357 9.91175 14.5719C9.73886 14.7334 9.57947 14.8438 9.43359 14.9031C9.29311 14.9677 9.14993 15 9.00405 15C8.85277 15 8.70689 14.9677 8.56641 14.9031C8.42593 14.8438 8.26655 14.7334 8.08825 14.5719C7.6344 14.1357 7.12652 13.8099 6.56461 13.5945C6.0081 13.3791 5.43809 13.2687 4.85457 13.2633C4.28726 13.2579 3.73615 13.3414 3.20126 13.5137C2.67177 13.6914 2.1828 13.9311 1.73435 14.2326C1.58307 14.3296 1.44259 14.4103 1.31292 14.475C1.18325 14.545 1.05088 14.58 0.915804 14.58C0.67267 14.58 0.459253 14.51 0.275552 14.37C0.0918505 14.2299 0 13.993 0 13.6591ZM1.30482 12.9725C1.73165 12.6656 2.25844 12.4206 2.88519 12.2375C3.51193 12.0544 4.1792 11.9628 4.88699 11.9628C5.33543 11.9628 5.77308 12.014 6.19991 12.1163C6.62674 12.2132 7.02116 12.3479 7.38316 12.5202C7.75056 12.6925 8.07204 12.8891 8.34759 13.1099V2.93215C8.06123 2.43673 7.60468 2.04093 6.97794 1.74475C6.35119 1.44857 5.65421 1.30048 4.88699 1.30048C4.38451 1.30048 3.90095 1.3678 3.43629 1.50242C2.97704 1.63166 2.56101 1.81475 2.1882 2.0517C1.8154 2.28864 1.52094 2.56597 1.30482 2.88368V12.9725ZM9.65241 13.1099C9.92796 12.8891 10.2494 12.6925 10.6168 12.5202C10.9842 12.3479 11.3787 12.2132 11.8001 12.1163C12.2269 12.014 12.6673 11.9628 13.1211 11.9628C13.8235 11.9628 14.4881 12.0544 15.1148 12.2375C15.7416 12.4206 16.2683 12.6656 16.6952 12.9725V2.88368C16.4791 2.56597 16.1846 2.28864 15.8118 2.0517C15.439 1.81475 15.0203 1.63166 14.5556 1.50242C14.0964 1.3678 13.6182 1.30048 13.1211 1.30048C12.3485 1.30048 11.6488 1.44857 11.0221 1.74475C10.3953 2.04093 9.93877 2.43673 9.65241 2.93215V13.1099Z" fill="#CCCCCC"/>
      </svg>
      """
    let reactionIcon = """
      <svg class="button-icon" width="14" height="12" viewBox="0 0 14 12" fill="none" aria-hidden="true">
        <path d="M12.0307 1.69986C11.4024 1.07447 10.5705 0.732655 9.68264 0.732655C8.79479 0.732655 7.96036 1.077 7.332 1.70239L7.00382 2.02901L6.67056 1.69733C6.0422 1.07194 5.20523 0.72506 4.31738 0.72506C3.43207 0.72506 2.59764 1.0694 1.97182 1.69226C1.34346 2.31766 0.997478 3.14814 1.00002 4.03179C1.00002 4.91544 1.34855 5.74339 1.97691 6.36878L6.75451 11.1238C6.82066 11.1896 6.9097 11.2251 6.99619 11.2251C7.08269 11.2251 7.17173 11.1921 7.23787 11.1263L12.0256 6.37891C12.654 5.75351 13 4.92303 13 4.03938C13.0025 3.15573 12.6591 2.32525 12.0307 1.69986ZM11.5423 5.8953L6.99619 10.4022L2.46027 5.88771C1.96165 5.39145 1.6869 4.73314 1.6869 4.03179C1.6869 3.33044 1.9591 2.67213 2.45772 2.1784C2.9538 1.68467 3.61524 1.41122 4.31738 1.41122C5.02206 1.41122 5.68604 1.68467 6.18466 2.18093L6.7596 2.75315C6.89443 2.88735 7.11067 2.88735 7.2455 2.75315L7.81535 2.186C8.31397 1.68973 8.97795 1.41628 9.68009 1.41628C10.3822 1.41628 11.0437 1.68973 11.5423 2.18346C12.0409 2.67973 12.3131 3.33803 12.3131 4.03938C12.3157 4.74073 12.0409 5.39904 11.5423 5.8953Z" fill="#CCCCCC" stroke="#CCCCCC" stroke-width="0.5"/>
      </svg>
      """
    let indexButton =
      actions.showsIndex
      ? "<button class=\"action\" data-action=\"index\"\(input.canReact ? "" : " disabled")>\(indexIcon)收藏</button>"
      : ""
    let reactionButton =
      actions.showsReaction && input.showReactions
      ? "<button class=\"action\" data-action=\"reactionPicker\" data-post-id=\"\(postID)\"\(input.canReact ? "" : " disabled")>\(reactionIcon)贴贴</button>"
      : ""

    return """
      <div class="main-actions">
        <button class="action" data-action="newReply"\(replyDisabled)>\(replyIcon)\(actions.replyCount) 回复</button>
        \(indexButton)
        \(reactionButton)
      </div>
      """
  }

  private func renderReactions(
    _ reactions: [PostDocumentRenderInput.Reaction],
    postID: Int,
    input: PostDocumentRenderInput
  ) throws -> String {
    guard input.showReactions, !reactions.isEmpty else {
      return ""
    }

    var buttons = ""
    for reaction in reactions {
      try Task.checkCancellation()
      let selectedClass = reaction.selected ? " selected" : ""
      let disabled = input.canReact ? "" : " disabled"
      let image: String
      if let item = BBCodeSmileyCatalog.item(for: reaction.smileyCode) {
        let source = "\(Self.stickerURLScheme)://smiley/\(item.code)"
        image = "<img src=\"\(source.bbcodeHTMLEscaped)\" alt=\"\">"
      } else {
        image = "<span>(\(reaction.smileyCode.bbcodeHTMLEscaped))</span>"
      }

      buttons.append(
        """
        <button class="reaction\(selectedClass)" data-action="reaction" data-post-id="\(postID)" data-value="\(reaction.value)"\(disabled)>
          \(image)<span>\(reaction.count)</span>
        </button>
        """
      )
    }

    return "<div class=\"reactions\">\(buttons)</div>"
  }

  private func renderBBCode(_ code: String, domains: BangumiDomains) throws -> String {
    try Task.checkCancellation()
    let html = try? BBCode().html(
      code,
      args: [
        "textSize": 16,
        "domains": domains,
        "smileyURLScheme": Self.stickerURLScheme,
      ]
    )
    try Task.checkCancellation()

    return html ?? code.bbcodeHTMLEscaped
  }
}
