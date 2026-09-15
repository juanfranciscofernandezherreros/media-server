# Repository development rules

## Scope and definitions

A **development change** is any operation that modifies repository or delivery state, including modifying files; creating or changing development branches; creating commits; pushing; creating or modifying pull requests; merging; creating tags; and creating or publishing releases.

Purely read-only work is not a development change and does not require a version or the Gitflow workflow. This includes analysis, code review, explanation, planning, inspection, and reading files.

## Required user values

Before any development change, stop and ask the user for, then explicitly receive, all three values:

- the exact semantic version in `X.Y.Z` format;
- the intended SemVer impact: `major`, `minor`, or `patch`;
- the intended work type: `feature`, `bugfix`, or `hotfix`.

`feature` is planned work for the next release. `bugfix` is a non-urgent correction intended for the next release. `hotfix` is an urgent correction to the version currently published from `main`.

Never infer, correct, calculate, increment, substitute, reuse, tag, or publish a version automatically. Do not edit files, create a development branch, commit, push, open or modify a pull request, merge, create a tag, or publish a release until the user has explicitly provided all three values.

The agent may consult the latest published version only to validate the supplied values; it must never use that reference to invent or increment a version. The supplied version and SemVer impact must be coherent with that reference:

- `major` increases the major component and resets later components according to SemVer;
- `minor` retains the major component, increases the minor component, and resets patch;
- `patch` retains major and minor and increases patch.

If they are incompatible, stop, explain the conflict, and do not correct either value automatically.

Preserve the exact user-supplied version, SemVer impact, and work type throughout the workflow. The final tag, if publication is explicitly authorized, must be exactly `vX.Y.Z` for the confirmed version.

## Required synchronization and safety checks

At the start of each development task or Gitflow workflow, before its first state-changing operation, first switch to `main` and run:

```bash
git fetch origin
git pull --ff-only origin main
```

`main` is clean and synchronized only when all of the following are true:

- `git status --porcelain` produces no output;
- the mandatory fetch and pull finish successfully;
- `git rev-parse HEAD` exactly equals `git rev-parse origin/main`;
- no merge, rebase, cherry-pick, or revert is incomplete.

If any check fails, including a dirty working tree, a pull that cannot fast-forward, differing hashes, or an incomplete Git operation, stop and report the problem. Do not modify files or change strategy.

Before creating a `feature/*` or `bugfix/*` branch, then switch to `develop` and run:

```bash
git switch develop
git pull --ff-only origin develop
```

`develop` is clean and synchronized only when all of the following are true:

- `git status --porcelain` produces no output;
- the mandatory pull finishes successfully;
- `git rev-parse HEAD` exactly equals `git rev-parse origin/develop`;
- no merge, rebase, cherry-pick, or revert is incomplete.

If any check fails, stop and report the problem. Every `feature/*` and `bugfix/*` branch must be created from the current synchronized `develop` HEAD, never from `main` or a temporary branch. Every `hotfix/*` branch must be created from the current synchronized `main` HEAD.

Before beginning a development branch where practical, and always before release preparation or publication, ensure the version has not already been used:

```bash
git tag --list "vX.Y.Z"
git ls-remote --tags origin "refs/tags/vX.Y.Z"
```

When GitHub CLI or API access is available, also check whether a GitHub Release exists for that version. If the tag or release already exists, stop: do not move tags, reuse the version, or invent an alternative.

## Gitflow branches

Only `main` and `develop` are permanent branches. Never create or use a permanent `releases` branch.

```text
main
  |
  |---- hotfix/X.Y.Z-description
  |          |
  |          +----> main
  |          +----> develop
  |
develop
  |
  |---- feature/X.Y.Z-description ----> develop
  |
  |---- bugfix/X.Y.Z-description -----> develop
  |
  |---- release/X.Y.Z
             |
             +----> main
             +----> develop
```

Create branches only in these formats:

- `feature/X.Y.Z-short-description` from synchronized `develop` for confirmed `feature` work;
- `bugfix/X.Y.Z-short-description` from synchronized `develop` for confirmed `bugfix` work;
- `hotfix/X.Y.Z-short-description` from synchronized `main` for confirmed `hotfix` work;
- `release/X.Y.Z` from synchronized `develop` to prepare an authorized release.

In every format, `X.Y.Z` is the exact user-supplied version. For `feature/*`, `bugfix/*`, and `hotfix/*`, `short-description` must be lowercase kebab-case, with no spaces, underscores, or uppercase letters, and the prefix must exactly match the confirmed work type. `release/X.Y.Z` is an authorized promotion branch, not a user work type, and is exempt from that prefix comparison. Reject a branch name with a missing version or invalid description.

## Merge and promotion policy

Never rewrite published history. Do not force-push `main`, `develop`, release tags, or shared branches unless the user explicitly instructs it and repository policy permits it.

For `feature/*` and `bugfix/*`, use the pull-request policy configured by the repository; do not bypass required checks or branch protection. After GitHub confirms a successful merge into `develop`, delete the merged branch both locally and from `origin`; never delete it earlier.

For `release/*` and `hotfix/*` promotions, do not use rebase. Preserve an auditable Gitflow history. A release branch is temporary: create `release/X.Y.Z` from `develop`, integrate it into both `main` and `develop`, then delete it locally and from `origin` only after the required merges and authorized publication are complete. A hotfix branch is likewise temporary: create it from `main`, integrate it into both `main` and `develop`, then delete it locally and from `origin` only after confirmed merges and authorized publication.

## Separate authorization boundaries

Development work, release promotion, and version publication are separate actions. Completing a feature or bugfix and merging it into `develop` does not authorize release preparation or publication. After that merge, stop unless the user explicitly instructs otherwise. Do not automatically create `release/X.Y.Z`, merge to `main`, create `vX.Y.Z`, or publish a GitHub Release.

An urgent hotfix may be prepared through the stated Gitflow path, but creating its final tag and GitHub Release also requires explicit user authorization. Publish a tag or GitHub Release only from `main`, only after the required merges, and only with that authorization.

These checks apply to every development change, even when the requested change appears small.
