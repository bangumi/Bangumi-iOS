---
name: appstore-release
description: "Run the Bangumi-iOS App Store release workflow. Use when asked to release or publish the next version: create the App Store Connect version for the current development version, write zh-Hans whatsNew, attach the latest VALID build, submit for review, then run make minor and land the next-version-cycle PR through the fork workflow. Also covers verifying the CI-created GitHub Release and build upload."
---

# Bangumi-iOS App Store Release

Release the current development version to the App Store, then start the next version cycle.

## Key Facts

- App Store Connect app: `Bangumi Riff`, app ID `6499502714`, platform iOS only, primary locale `zh-Hans`. Verify with `asc apps list --name "Bangumi"` before remote changes; the ID can drift.
- The repo's `MARKETING_VERSION` runs one version ahead of the store. Releasing means submitting the *current* `MARKETING_VERSION` at HEAD (e.g. submit 3.3 while the store sells 3.2), then bumping to the next version.
- `releaseType` is `MANUAL`: after review approval the user releases it themselves. Never run `asc versions release` unless explicitly asked.
- CI (`publish.yml`) on push to `main`: any `CURRENT_PROJECT_VERSION` change uploads the HEAD build to ASC; a minor transition (`X.Y` -> `X.Y+1`) additionally creates the GitHub Release `vX.Y` at the pre-bump commit. GitHub Releases carry no IPA artifacts.
- `main` on `bangumi/Bangumi-iOS` is protected (required check `Build iOS`). Direct pushes are rejected; version bumps land through the fork PR workflow in AGENTS.md.

## Guardrails

- Work from a clean git state; `make minor`/`make bump` require it and must own all version mutations. Never edit `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` manually.
- Do not create duplicate ASC versions; reuse an existing editable version in `PREPARE_FOR_SUBMISSION`.
- Stop before submission if the build is not `VALID` or metadata is incomplete.
- Submission to review is externally visible; confirm the user asked to release before `submissions-submit`.
- Keep release notes user-facing: exclude bump commits, CI, refactors, file/class names.
- Use `gh pr create --body-file`; never pass Markdown bodies inline.

## Phase 1: Determine What To Release

```bash
git fetch upstream && git status -sb
grep -m1 MARKETING_VERSION Bangumi.xcodeproj/project.pbxproj
grep -m1 CURRENT_PROJECT_VERSION Bangumi.xcodeproj/project.pbxproj
asc versions list --app 6499502714 --platform IOS --pretty   # find READY_FOR_SALE version
asc builds list --app 6499502714 --pretty                    # latest builds and states
```

The release target is the repo's current `MARKETING_VERSION` with the latest ASC build whose build number matches `CURRENT_PROJECT_VERSION` at HEAD. If ASC already has that build but no version object, the previous cycle ended right after the bump — proceed to submit it.

## Phase 2: Create Or Reuse The ASC Version

```bash
asc versions list --app 6499502714 --version "$version" --platform IOS --pretty
asc versions create --app 6499502714 --version "$version" --platform IOS --pretty   # only if missing
```

Record the version ID. State must be `PREPARE_FOR_SUBMISSION` before metadata/build changes.

## Phase 3: Write whatsNew (zh-Hans)

1. Read the *previous* released version's whatsNew via `asc localizations list --version <prev_version_id> --pretty` — both as style reference and to find which commits it already covered (it may describe commits after the previous bump).
2. Draft notes from the uncovered commits up to HEAD. Read full commit bodies, not only subjects.
3. Follow the established structure: `新功能` / `改进` / `修复` sections with `- ` bullets, concise Chinese, user-facing phrasing.
4. Update, preserving everything else (description, keywords, URLs stay unchanged unless the user asks):

```bash
asc localizations update --version "$version_id" --locale zh-Hans --whats-new "$notes" --pretty
```

`--version` takes the *version* ID, not the localization ID. Read the localization back and confirm `description` is unchanged and `whatsNew` matches the draft.

## Phase 4: Attach Build And Submit

```bash
asc builds list --app 6499502714 --pretty   # confirm target build is VALID, usesNonExemptEncryption=false
asc versions attach-build --version-id "$version_id" --build "$build_id" --pretty
asc versions view --version-id "$version_id" --include-build --pretty   # `get` was removed; use `view`
```

Submit:

```bash
submission_id=$(asc review submissions-create --app 6499502714 --platform IOS --pretty \
  | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("id") or data["data"]["id"])')
asc review items-add --submission "$submission_id" --item-type appStoreVersions --item-id "$version_id" --pretty
asc review submissions-submit --id "$submission_id" --confirm --pretty
```

Verify `asc versions view` reports `WAITING_FOR_REVIEW`. Remind the user that release after approval is manual and theirs to trigger.

## Phase 5: Start The Next Version Cycle

From clean, synced `main`:

```bash
fork_owner=$(git remote get-url origin | sed -E 's#(git@github\.com:|https://github\.com/)([^/]+)/.*#\2#')
git switch -c "release/bump-$next_version"
make minor        # creates commit "chore: bump version to $next_version"
git push -u origin "release/bump-$next_version"
gh pr create --repo bangumi/Bangumi-iOS --base main --head "${fork_owner}:release/bump-$next_version" \
  --title "chore: bump version to $next_version" --body-file /tmp/pr-body.md
gh pr view <PR> --json url,title,body,headRefName,baseRefName,state,statusCheckRollup
gh pr view <PR> --json commits,files    # scope: exactly one commit, only project.pbxproj
```

Wait for `Build iOS` to pass, then squash-merge and resync. The squash merge produces a *new* commit hash on upstream, so reset local `main` instead of pulling:

```bash
gh pr merge <PR> --repo bangumi/Bangumi-iOS --squash --delete-branch \
  --subject "chore: bump version to $next_version" --body "..."
git fetch --prune origin && git fetch --prune upstream
git switch main
git diff HEAD upstream/main --stat    # must be empty (same content, different hash)
git reset --hard upstream/main && git push origin main
git branch -d "release/bump-$next_version"
```

## Phase 6: Verify Automation

```bash
gh release view "v$version" --repo bangumi/Bangumi-iOS --json tagName,targetCommitish,url
gh run list --repo bangumi/Bangumi-iOS --workflow publish.yml --limit 2 \
  --json status,conclusion,headSha
```

- GitHub Release `v$version` must exist, targeting the pre-bump commit.
- The publish run for the merge commit must end `success` (detect / release / upload jobs).
- Confirm the new build appears on ASC (`asc builds list`); it can take a few minutes after the upload job succeeds. The new cycle's build does not need an ASC version object until the next release.

## Final Report

- ASC: version ID, build ID, submission ID, final state (`WAITING_FOR_REVIEW`).
- whatsNew text submitted.
- Next-cycle PR URL and merge status; GitHub Release URL and target commit.
- Current local branch, HEAD, and worktree cleanliness.
