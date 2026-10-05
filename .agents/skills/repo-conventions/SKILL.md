---
name: repo-conventions
description: Bangumi-iOS subsystem conventions and invariants — GRDB storage and migration discipline, client architecture boundaries (APIClient, services, repositories, AppConfig, AppContext), BBCode rendering and image preview pipelines, animation tokens and haptics. Use when working on the local database schema or migrations, persistence, API client/services/repositories, BBCode rendering, image preview and sharing, animation, or haptic feedback.
---

# Repo Conventions

Subsystem conventions and invariants for Bangumi-iOS. `AGENTS.md` holds repo-wide rules; this file holds the per-subsystem boundaries. When a change alters one of these boundaries, update this file in the same change.

## Storage And Migrations

- Persistent storage is backed by GRDB. Do not reintroduce SwiftData storage unless the user explicitly asks for it.
- SwiftData references should stay limited to the one-time legacy import path, such as `LegacySwiftDataMigrator`, old schema definitions, and the old SwiftData migration plan.
- Keep schema setup and migrations centralized in `DatabaseFactory` with `DatabaseMigrator`.
- Once a migration has shipped, treat its registered name and body as append-only history. Do not rename, remove, reorder, or rewrite old migrations.
- For every persistent table, column, index, constraint, or stored payload format change, add a new descriptive `registerMigration(...)` after existing migrations.
- New non-null columns must either have a safe default or be introduced as nullable and backfilled before enforcing non-null behavior.
- For SQLite changes that cannot be expressed safely with `ALTER TABLE`, create a replacement table, copy data explicitly, recreate indexes and foreign keys, then drop/rename inside the migration.
- Treat BLOB or JSON payload shape changes as schema changes. Prefer backward-compatible decoders; otherwise migrate the payloads explicitly or clear only cache tables that are safe to rebuild from the network.
- No force casts (`as!`) on GRDB `Row` subscripts; use the generic converting subscript (`let date: Date = row["created_at"]`) or `as?` with a fallback.
- When building JSON strings for storage or cache keys, use `JSONSerialization` with `sortedKeys` for stable raw values.
- In non-SQL code, do not use unconstrained interpolated literals inside `map` or `compactMap` followed by `joined()`. GRDB may infer the element type as `SQL` and leak `SQL(elements: ...)` descriptions into rendered output. Extract interpolated fragments into a helper that explicitly returns `String`, or append them to a typed `String` accumulator.
- Validate storage changes with both a fresh database path and an upgraded existing database path, then run `make build`.

### GRDB Migration Discipline

Runtime GRDB migrations in `DatabaseFactory` are historical artifacts and must be treated as immutable once committed.

- Do not mutate already-registered GRDB migrations such as `createGRDBSchemaV1` or `createLocalMigrationMarkers` to add new columns, defaults, indexes, or table shape changes.
- Do not treat helper methods called from baseline migrations, such as `createSubjects` or `createSimpleCaches`, as current-schema builders. They define the frozen baseline for that migration.
- Any GRDB table shape change must be added as a new numbered migration after the latest registered migration. Fresh installs should reach the latest schema by running the baseline migration plus every later migration in order.
- When adding a new persisted field to a GRDB record, update the runtime record model and `CodingKeys` if present, then add a new migration that backfills a safe default for existing databases.
- Validate both upgrade and fresh install paths: an existing `Bangumi.sqlite` must migrate forward, and a new empty database must run all migrations without duplicate-column or missing-column failures.

## Client Architecture

- Keep `APIClient` as the low-level HTTP/session/token client only. Do not add feature-specific business APIs, database loading, Spotlight indexing, UI state, or app runtime state to it.
- Put remote API operations in focused `*Service` types. Put operations that combine remote API calls with local GRDB writes, cache updates, or indexing in focused `*Repository` types.
- Long-lived SSE streams are the one exception to `APIClient`'s buffered-request model: `APIClient.serverSentEventPayloads(url:auth:)` opens the connection on a per-call session with infinite timeouts (the cached request sessions cap requests at 10s/20s and would kill the stream), parses `data:` frames, and yields raw payloads. Feature services wrap it into typed streams that own reconnect/backoff and decoding (e.g. `TimelineService.liveEvents(mode:)`); views consume those with `.task(id:)` keyed on the enable state so toggling off, switching modes, or leaving the view cancels the stream.
- Views and components should call services, repositories, `AuthService`, `AppContext`, or other narrow app services. They should not call `APIClient.shared` directly.
- Keep `UserDefaults` access centralized in `AppConfig` using typed static properties. Avoid new raw `UserDefaults.standard` calls outside that boundary; `@AppStorage` remains acceptable in SwiftUI views when it is the local view binding mechanism.
- App runtime state such as the GRDB `DatabaseOperator` and app version display should live behind `AppContext` / `AppMetadata`, not in `APIClient`.
- The paged `GET /p1/collections/subjects?since=` sync lives in `CollectionRepository.refreshCollections`; progress views (pull-to-refresh, first full sync) and background reconcile must share it instead of re-implementing the fetch loop. The `AppConfig.collectionsUpdatedAt` watermark is advanced with `max(...)` only, because views and the reconciler advance it concurrently.
- After `EpisodeRepository.updateEpisodeCollection` succeeds, `CollectionReconciler` runs a fire-and-forget incremental reconcile so server truth (e.g. `epStatus`, which also counts watched SP episodes) overwrites the local simulation without blocking the UI. The reconcile skips `checkLoadEpisodes` — simulated episode statuses are already correct, and a background reload failure must not alert the user; only view-driven refreshes reload episodes. New episode-marking paths should go through `EpisodeRepository` to inherit this; reconcile failures stay silent (log only) because the watermark is left untouched and the next pull-to-refresh still covers the gap.
- Device and platform metadata that requires main-actor-safe setup should be initialized from an explicit `@MainActor` setup path, such as `MainApp.init`. Never bypass actor isolation for convenience.
- For User-Agent device model values, prefer a safe platform helper approach such as `uname(&utsname)` during main-actor setup, then cache the resulting string in `AppConfig`.

## BBCode And Image Preview

- BBCode image rendering flows through:
  - `App/Features/BBCode/Renders/PreparedDocument.swift`
  - `App/Features/BBCode/Views/BBCodeUIKitView.swift`
- Inter-block spacing is a pair table keyed by (upper, lower) block type; blocks carry no vertical margins/insets of their own. First and last blocks keep zero outer gap.
  - WebView path (`PostDocumentRenderer`): `.post-content` resets all block margins to 0 and applies adjacent-sibling rules — default 8px, `p + p` 5px, image-adjacent 6px, quote-adjacent 10px, list-adjacent 10px, code-adjacent 12px. Quote and list interiors use a fixed compact gap (4–5px) instead of re-entering the table. Quotes render as a 3px rounded left bar with 4px vertical padding and 20px text offset.
  - UITextView path (`BBCodeBlocksContainerView` + `BBCodeLayoutMetrics.spacing(between:and:)`): quote-adjacent 10, mask/list-adjacent 8, image-adjacent 6, text–text 5, applied via `UIStackView.setCustomSpacing`; nested containers (quote/mask/list items) run the same table.
  - Code blocks are text payload in the UITextView path, so they follow text spacing there; the 12px code tier only exists in the WebView path.
- When fixing image alignment, preserve the asset's natural visual size. Do not solve centering by making all images full width.
- Thumbnail/downsample logic must not upscale small images.
- Treat vector/unconstrained SVG images carefully; avoid forcing them through raster thumbnail paths that expand them to container width.
- For image preview sharing, prefer directly presenting `UIActivityViewController` from UIKit when the existing code path is UIKit-based.
- Share sheet previews should provide image data and `LPLinkMetadata` when needed; sharing only a URL can produce empty previews and miss save-image behavior.
- In image preview controls, prefer native system control styling. Keep only minimal shape or hit-area constraints such as circular button shape when needed.
- The SwiftUI previewer (`ImagePreviewer`) is a gallery: it takes `[URL]` + initial index (single-image callers are a one-page gallery), pages with a horizontal `ScrollView` of full-width pages + 20pt inter-page spacing (the gap only shows mid-swipe, like Telegram's pager) and `.scrollTargetBehavior(.viewAligned)` (`.paging` cannot express the width+gap stride), and shows a bottom thumbnail strip only when there is more than one page.
- Pull-to-dismiss and horizontal paging are both gated on the current page's zoom state reported by `ZoomableImageScrollView`: the dismiss `DragGesture` only takes over at minimum zoom scale, and the pager is `.scrollDisabled` while zoomed so horizontal pans scroll the zoomed page instead of turning pages. Keep these gates in sync when changing either side. Additionally, on iOS 26+ with an active zoom transition the system owns pull-to-dismiss (interactive zoom-out), so the custom `DragGesture` is masked off via `zoomTransitionInteractive` / `systemOwnsPullDismiss`; on earlier systems the custom gesture stays.
- The UIKit BBCode path (`ImagePreviewPresenter`) still presents single images only; do not widen it without an explicit request.

## Animation And Haptics

- Animation tokens live in `App/Helpers/Animation.swift` as static properties on `Animation`. Pick by role: `contentSwap` for small in-place text/icon/state swaps, `layoutShift` for section visibility and card expansion, `springy` for overlay entrances, `overlayExit` for overlay dismissals, `pressDown`/`pressUp` for button press micro-interactions, `pressSubtle` for compact controls such as chips.
- New code must use these tokens instead of `withAnimation(.default)` or ad-hoc parameters. If no token fits, add one with a usage note rather than inlining parameters. Migrating pre-existing call sites is opt-in; do not batch-rewrite them.
- Shared micro-effect modifiers live in `App/Helpers/ViewEffects.swift`: `shake(trigger:)` signals validation failure (fire `Haptics.notify(.error)` alongside the trigger increment at the call site), and `staggeredIn(index:)` plays a first-appearance fade+rise staggered by index for horizontal image rows (plays once per view identity, so lazy-stack re-entries and page appends of already-seen rows stay still). Numeric labels that change in place use `.contentTransition(.numericText())` paired with `.animation(.contentSwap, value:)`; fixed-size badges and episode chips stay exempt per AGENTS.md rule 7.
- Haptics go through `Haptics` in `App/Helpers/Haptics.swift` at three semantic levels: `selection()` for pickers, swipe-to-select, and toggles; `impact()` for tap/action triggers (default `.light`, `.medium` only for weighty triggers such as batch operations, form commits, and deliberate gestures); `notify(_:)` only when an operation has a clear success/failure/warning outcome.
- Toasts go through `Notifier.notify(message:type:duration:action:)`. The optional `type` (`.success`/`.error`) fires `Haptics.notify` at trigger time and draws a glyph inside the countdown ring; status-confirmation toasts stay untyped and silent. Duration is computed internally (short confirmations 3s, reading-paced 5–8s, action toasts 5s) unless a call site overrides it.
- Generators are created on demand and discarded at the call site; do not add singletons or caching. `ScrubHaptics` in `ProgressEpisodeTrackView` is the sanctioned exception because scrubbing needs prepared generators for latency.
- iOS 17 `.sensoryFeedback` call sites stay as-is; do not rewrite them to `Haptics`.
