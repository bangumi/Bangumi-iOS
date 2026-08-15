# AGENTS.md

This file provides repository-specific guidance for coding agents working in
this repository.

## Project Overview

- Bangumi-iOS is a SwiftUI iOS app using Swift 6, GRDB, and Xcode.
- The main app target is `Bangumi` in `Bangumi.xcodeproj`.
- `BBCode/` is a local Swift package used by the app for BBCode rendering.
- The app is distributed as `Bangumi Riff` in App Store Connect.

## Workflow Rules

- Communicate with the user in Simplified Chinese by default.
- Keep code, comments, identifiers, commit messages, PR titles, and Markdown code blocks in English.
- Do not run `make format` in this repository unless the user explicitly asks for it. If formatting is needed, keep it local to the touched code.
- Prefer small, reviewable changes that match existing SwiftUI and GRDB patterns.
- Do not include incidental `Bangumi.xcodeproj/project.pbxproj` changes in a PR unless the user asked for a version/build bump or the project file change is truly required.
- Do not use unsafe language features, unsafe concurrency bypasses, or unsafe runtime assumptions anywhere in this repository. This is a hard global requirement. In Swift, this includes `unsafe` APIs, `nonisolated(unsafe)`, `MainActor.assumeIsolated`, unchecked actor isolation workarounds, and similar constructs.
- In non-SQL code, do not use unconstrained interpolated literals inside `map` or `compactMap` followed by `joined()`. GRDB may infer the element type as `SQL` and leak `SQL(elements: ...)` descriptions into rendered output. Extract interpolated fragments into a helper that explicitly returns `String`, or append them to a typed `String` accumulator.

## Storage And Migration Rules

- Persistent storage is backed by GRDB. Do not reintroduce SwiftData storage unless the user explicitly asks for it.
- SwiftData references should stay limited to the one-time legacy import path, such as `LegacySwiftDataMigrator`, old schema definitions, and the old SwiftData migration plan.
- Keep schema setup and migrations centralized in `DatabaseFactory` with `DatabaseMigrator`.
- Once a migration has shipped, treat its registered name and body as append-only history. Do not rename, remove, reorder, or rewrite old migrations.
- For every persistent table, column, index, constraint, or stored payload format change, add a new descriptive `registerMigration(...)` after existing migrations.
- New non-null columns must either have a safe default or be introduced as nullable and backfilled before enforcing non-null behavior.
- For SQLite changes that cannot be expressed safely with `ALTER TABLE`, create a replacement table, copy data explicitly, recreate indexes and foreign keys, then drop/rename inside the migration.
- Treat BLOB or JSON payload shape changes as schema changes. Prefer backward-compatible decoders; otherwise migrate the payloads explicitly or clear only cache tables that are safe to rebuild from the network.
- Validate storage changes with both a fresh database path and an upgraded existing database path, then run `make build`.

### GRDB Migration Discipline

Runtime GRDB migrations in `DatabaseFactory` are historical artifacts and must be treated as immutable once committed.

- Do not mutate already-registered GRDB migrations such as `createGRDBSchemaV1` or `createLocalMigrationMarkers` to add new columns, defaults, indexes, or table shape changes.
- Do not treat helper methods called from baseline migrations, such as `createSubjects` or `createSimpleCaches`, as current-schema builders. They define the frozen baseline for that migration.
- Any GRDB table shape change must be added as a new numbered migration after the latest registered migration. Fresh installs should reach the latest schema by running the baseline migration plus every later migration in order.
- When adding a new persisted field to a GRDB record, update the runtime record model and `CodingKeys` if present, then add a new migration that backfills a safe default for existing databases.
- Validate both upgrade and fresh install paths: an existing `Bangumi.sqlite` must migrate forward, and a new empty database must run all migrations without duplicate-column or missing-column failures.

## Client Architecture Rules

- Keep `APIClient` as the low-level HTTP/session/token client only. Do not add feature-specific business APIs, database loading, Spotlight indexing, UI state, or app runtime state to it.
- Put remote API operations in focused `*Service` types. Put operations that combine remote API calls with local GRDB writes, cache updates, or indexing in focused `*Repository` types.
- Views and components should call services, repositories, `AuthService`, `AppContext`, or other narrow app services. They should not call `APIClient.shared` directly.
- Keep `UserDefaults` access centralized in `AppConfig` using typed static properties. Avoid new raw `UserDefaults.standard` calls outside that boundary; `@AppStorage` remains acceptable in SwiftUI views when it is the local view binding mechanism.
- App runtime state such as the GRDB `DatabaseOperator` and app version display should live behind `AppContext` / `AppMetadata`, not in `APIClient`.
- Device and platform metadata that requires main-actor-safe setup should be initialized from an explicit `@MainActor` setup path, such as `MainApp.init`. Never bypass actor isolation for convenience.
- For User-Agent device model values, prefer a safe platform helper approach such as `uname(&utsname)` during main-actor setup, then cache the resulting string in `AppConfig`.

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
- Release automation treats build upload and GitHub Release creation separately:
  - Any `CURRENT_PROJECT_VERSION` change uploads the current HEAD build to App Store Connect.
  - A major transition such as `1.13 -> 2.0` uploads the `2.0` build but does not create a GitHub Release.
  - A same-major minor transition such as `2.0 -> 2.1` creates the GitHub Release for the previous marketing version (`v2.0`) at the previous commit, while the HEAD build can continue uploading as `2.1`.
  - GitHub Releases do not upload IPA artifacts.
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
- If the user also asks for `make bump`, keep the bump as its own commit.

## SwiftUI UI Rules

- Use SwiftUI-first implementations unless the existing local code path is UIKit-based.
- Do not use `HStack` inside a toolbar. Group adjacent toolbar actions with `ToolbarItemGroup` at the appropriate placement.
- Do not put live persistent models directly into `NavigationPath` / `NavigationLink(value:)` values. Use stable IDs or explicit value snapshots instead; live models can make SwiftUI navigation hashing/diffing unstable across OS releases.
- Prefer system button sizing and styles. Avoid hand-written frames, font overrides, foreground colors, or wrapper views unless they are needed for hit testing or platform behavior.
- Keep SwiftUI animation ownership explicit: use `.animation(_:value:)` for local micro-interactions such as button press, hover, selection highlight, or compact control state only.
- Use `withAnimation` at the state mutation point for state transitions such as sheets, navigation-affecting state, list/content replacement, filter or sort changes, and page mode switches.
- For complex screens, prefer explicit animation in actions, async reload completion, or binding setters instead of scattering `.animation(_:value:)` across parent view modifiers.
- Preserve scroll performance by animating first-page/reload content replacement only when it improves continuity; avoid animating infinite-scroll append paths unless the interaction explicitly calls for it.
- For fixed-size badges, chips, and compact counters, do not use `.minimumScaleFactor(...)` or `.allowsTightening(true)` to hide layout pressure. These can cause the same UI element to render at different visual sizes across layout passes.
- Do not add `.fixedSize(horizontal: true, vertical: false)` to compact labels unless overflow has been considered. It can preserve font size but may expand beyond the intended layout for unexpectedly long text.
- For episode badges, keep the inherited font size stable; if text is too long, prefer normal one-line truncation/clipping behavior over per-item font scaling.
- VoiceOver support is out of scope for this app. Do not add VoiceOver-specific labels, traits, actions, or layout workarounds unless the user explicitly asks for them.

## BBCode And Image Preview Rules

- BBCode image rendering flows through:
  - `BBCode/Sources/BBCode/Renders/PreparedDocument.swift`
  - `BBCode/Sources/BBCode/Views/BBCodeUIKitView.swift`
- When fixing image alignment, preserve the asset's natural visual size. Do not solve centering by making all images full width.
- Thumbnail/downsample logic must not upscale small images.
- Treat vector/unconstrained SVG images carefully; avoid forcing them through raster thumbnail paths that expand them to container width.
- For image preview sharing, prefer directly presenting `UIActivityViewController` from UIKit when the existing code path is UIKit-based.
- Share sheet previews should provide image data and `LPLinkMetadata` when needed; sharing only a URL can produce empty previews and miss save-image behavior.
- In image preview controls, prefer native system control styling. Keep only minimal shape or hit-area constraints such as circular button shape when needed.

## App Store Connect Release Notes

- For ASC release tasks, do not assume app IDs, version IDs, or locale IDs. Query the current App Store Connect state first.
- The app ID previously used for `Bangumi Riff` was `6499502714`, with primary locale `zh-Hans`; verify before acting because this can drift.
- If the user says `desc 不变`, copy or preserve the previous version description and related metadata.
- When generating release notes, inspect full commit bodies, not only commit subjects.
- If the user says to follow the previous changelog style, use the existing Chinese structure such as `新功能 / 改进 / 修复` when it matches the previous version.
- After creating or updating ASC metadata, read it back and confirm that `description` stayed unchanged and `whatsNew` was updated.
