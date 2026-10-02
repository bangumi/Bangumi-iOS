---
name: repo-conventions
description: Bangumi-iOS subsystem conventions and invariants — GRDB storage and migration discipline, client architecture boundaries (APIClient, services, repositories, AppConfig, AppContext), BBCode rendering and image preview pipelines. Use when working on the local database schema or migrations, persistence, API client/services/repositories, BBCode rendering, or image preview and sharing.
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
- Views and components should call services, repositories, `AuthService`, `AppContext`, or other narrow app services. They should not call `APIClient.shared` directly.
- Keep `UserDefaults` access centralized in `AppConfig` using typed static properties. Avoid new raw `UserDefaults.standard` calls outside that boundary; `@AppStorage` remains acceptable in SwiftUI views when it is the local view binding mechanism.
- App runtime state such as the GRDB `DatabaseOperator` and app version display should live behind `AppContext` / `AppMetadata`, not in `APIClient`.
- Device and platform metadata that requires main-actor-safe setup should be initialized from an explicit `@MainActor` setup path, such as `MainApp.init`. Never bypass actor isolation for convenience.
- For User-Agent device model values, prefer a safe platform helper approach such as `uname(&utsname)` during main-actor setup, then cache the resulting string in `AppConfig`.

## BBCode And Image Preview

- BBCode image rendering flows through:
  - `BBCode/Sources/BBCode/Renders/PreparedDocument.swift`
  - `BBCode/Sources/BBCode/Views/BBCodeUIKitView.swift`
- When fixing image alignment, preserve the asset's natural visual size. Do not solve centering by making all images full width.
- Thumbnail/downsample logic must not upscale small images.
- Treat vector/unconstrained SVG images carefully; avoid forcing them through raster thumbnail paths that expand them to container width.
- For image preview sharing, prefer directly presenting `UIActivityViewController` from UIKit when the existing code path is UIKit-based.
- Share sheet previews should provide image data and `LPLinkMetadata` when needed; sharing only a URL can produce empty previews and miss save-image behavior.
- In image preview controls, prefer native system control styling. Keep only minimal shape or hit-area constraints such as circular button shape when needed.
