# AGENTS.md

This file provides repository-specific guidance for coding agents working in
this repository.

## Project Overview

- Bangumi-iOS is a SwiftUI iOS app using Swift 6, GRDB, and Xcode.
- The main app target is `Bangumi` in `Bangumi.xcodeproj`.
- `BBCode/` is a local Swift package used by the app for BBCode rendering.
- The app is distributed as `Bangumi Riff` in App Store Connect.

Subsystem conventions and invariants live in the `repo-conventions` skill
(`.agents/skills/repo-conventions/SKILL.md`) — load it when working on the
GRDB schema or migrations, client architecture (`APIClient` / services /
repositories / `AppConfig` / `AppContext`), BBCode rendering, or image
preview. The App Store release workflow lives in the `appstore-release`
skill.

## Workflow Rules

- Communicate with the user in Simplified Chinese by default.
- Keep code, comments, identifiers, commit messages, PR titles, and Markdown code blocks in English.
- Do not run `make format` in this repository unless the user explicitly asks for it. If formatting is needed, keep it local to the touched code.
- Prefer small, reviewable changes that match existing SwiftUI and GRDB patterns.
- Do not include incidental `Bangumi.xcodeproj/project.pbxproj` changes in a PR unless the user asked for a version/build bump or the project file change is truly required.
- Do not use unsafe language features, unsafe concurrency bypasses, or unsafe runtime assumptions anywhere in this repository. This is a hard global requirement. In Swift, this includes `unsafe` APIs, `nonisolated(unsafe)`, `MainActor.assumeIsolated`, unchecked actor isolation workarounds, and similar constructs.
- When a change alters a storage, client-architecture, or BBCode/image-preview boundary, update the `repo-conventions` skill in the same change.

## Coding Conventions

1. Use SwiftUI-first implementations unless the existing local code path is UIKit-based.
2. Do not use `HStack` inside a toolbar. Group adjacent toolbar actions with `ToolbarItemGroup` at the appropriate placement.
3. Do not put live persistent models directly into `NavigationPath` / `NavigationLink(value:)` values. Use stable IDs or explicit value snapshots instead; live models can make SwiftUI navigation hashing/diffing unstable across OS releases.
4. Prefer system button sizing and styles. Avoid hand-written frames, font overrides, foreground colors, or wrapper views unless they are needed for hit testing or platform behavior.
5. Keep SwiftUI animation ownership explicit: use `.animation(_:value:)` for local micro-interactions such as button press, hover, selection highlight, or compact control state only. Use `withAnimation` at the state mutation point for state transitions such as sheets, navigation-affecting state, list/content replacement, filter or sort changes, and page mode switches. For complex screens, prefer explicit animation in actions, async reload completion, or binding setters instead of scattering `.animation(_:value:)` across parent view modifiers.
6. Preserve scroll performance by animating first-page/reload content replacement only when it improves continuity; avoid animating infinite-scroll append paths unless the interaction explicitly calls for it.
7. For fixed-size badges, chips, and compact counters, do not use `.minimumScaleFactor(...)` or `.allowsTightening(true)` to hide layout pressure. These can cause the same UI element to render at different visual sizes across layout passes. Do not add `.fixedSize(horizontal: true, vertical: false)` to compact labels unless overflow has been considered. For episode badges, keep the inherited font size stable; if text is too long, prefer normal one-line truncation/clipping over per-item font scaling.
8. VoiceOver support is out of scope for this app. Do not add VoiceOver-specific labels, traits, actions, or layout workarounds unless the user explicitly asks for them.
9. No force casts (`as!`); use `as?` with a fallback.
10. No object-style environment dependencies (`@Environment(SomeType.self)`, `@EnvironmentObject`). Pass objects via initializers, context structs, or action closures; value-style `@Environment(\.x)` remains the norm. Pass shared object dependencies explicitly at tab/`NavigationStack` roots, sheets, full-screen covers, and hosting-controller boundaries instead of assuming environment inheritance survives those transitions.
11. Use `@Observable` for new observable types, not `ObservableObject` / `@Published`.
12. No inline `Binding(get:set:)` at call sites.
13. Do not store async/throwing/`@Sendable` closures in SwiftUI `View` value types (iOS 17 AttributeGraph crash risk); use concrete command types or passed-in services.
14. Never render an empty `HStack`/`VStack`; put the condition around the stack itself so nothing renders when there is no content.
15. Lazy containers (`LazyVStack`/`LazyHStack`/`LazyVGrid`) only for genuinely unbounded content (paginated or otherwise huge lists); eager stacks everywhere else — lazy stacks cache child frames and misplace children during animated layout updates.
16. Plain-style buttons and links (`.buttonStyle(.plain)`, text-or-label-only) must declare `.contentShape(Rectangle())` (or an equivalent hit shape) on the content inside the button's label so the whole frame is tappable; applying it on the button itself has no effect on hit-testing.

## Common Commands

```sh
make build
make bump
make release-ios
make artifact-ios
```

Command notes:

- `make build` builds the app for iOS simulator and runs `ensure-config`.
- Do not call `xcodebuild` directly for normal validation; use `make build` instead.
- `make bump` increments `CURRENT_PROJECT_VERSION` and creates a standalone commit like `chore: incr build ver to <n>`. It commits only `Bangumi.xcodeproj/project.pbxproj`.
- `make major` / `make minor` increment `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` together. Do not edit either version manually in `project.pbxproj`; use the Makefile targets.
- Build upload and GitHub Release automation behave differently per version transition; see the `appstore-release` skill's Key Facts.
- For BBCode package changes, still prefer the repository-provided build entrypoint first. Only use lower-level Xcode commands when the user explicitly asks or when `make build` cannot answer the specific failure.

## GitHub And PR Rules

- This repo is a fork workflow:
  - `origin` is the contributor's own fork
  - the upstream/default GitHub repo is `bangumi/Bangumi-iOS`
- For PRs to upstream, push a branch to the fork and use:

```sh
gh pr create --repo bangumi/Bangumi-iOS --base main --head '<fork-owner>:<branch>' --title '<semantic title>' --body-file /tmp/pr-body.md
```

- Always use `--body-file` for PR descriptions.
- After creating a PR, verify both metadata and scope:

```sh
gh pr view <number> --json url,title,body,headRefName,baseRefName
gh pr view <number> --json commits,files
```

- A PR is not done until the commit list and file list match the user-requested scope.
- Avoid zsh empty-glob failures when looking for PR templates. Prefer `find` or a shell with `nullglob` instead of raw `.github/PULL_REQUEST_TEMPLATE/*.md`.
- If the user says "提个 PR" or similar, complete branch creation, commit, push, PR creation, and post-create scope verification unless they explicitly ask to stop earlier.
- If the user also asks for `make bump`, keep the bump as its own commit. When several PRs are open in the same cycle, put the bump on the PR that merges last: `publish.yml` uploads the HEAD build to App Store Connect whenever `CURRENT_PROJECT_VERSION` changes on `main`, so only a bump on the final merge produces an upload containing all changes.

## App Store Releases

The release workflow (ASC version creation, zh-Hans whatsNew, build attach,
submission, next-cycle bump) lives in the `appstore-release` skill. Follow it
for any release or App Store Connect metadata task.
