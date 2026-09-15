# Repository development rules

Before making any development change in this repository, the agent must:

1. Stop and ask the user for all three of these values:

   - the exact semantic version in `X.Y.Z` format;
   - the intended SemVer impact: `major`, `minor`, or `patch`;
   - the intended work type: `feature`, `bugfix`, or `hotfix`.

   A `feature` is planned work for the next release, a `bugfix` is a non-urgent correction for the next release, and a `hotfix` is an urgent correction to the version currently published from `main`. Do not infer any of these values or calculate, increment, tag, or publish a version automatically. Do not edit files, create a development branch, commit, push, or open a pull request until the user explicitly provides all three values.
2. Switch to `main` and synchronize it using:

   ```bash
   git fetch origin
   git pull --ff-only origin main
   ```

3. Confirm that `main` is clean and synchronized. If the working tree is dirty, the pull cannot fast-forward, or synchronization fails, stop and report the problem instead of changing files.
4. Before creating a `feature/*` or `bugfix/*` branch, switch to `develop` and synchronize it using:

   ```bash
   git switch develop
   git pull --ff-only origin develop
   ```

5. Confirm that `develop` is clean and synchronized. Every `feature/*` and `bugfix/*` branch must be created from the current synchronized `develop` HEAD, never from `main` or another temporary branch. If the working tree is dirty, the pull cannot fast-forward, or synchronization fails, stop and report the problem instead of creating the development branch.
6. Follow the Gitflow promotion model. Only `main` and `develop` are permanent branches:

   ```text
   develop -> feature/X.Y.Z-description -> develop
   develop -> bugfix/X.Y.Z-description -> develop
   develop -> release/X.Y.Z -> main and develop -> tag/release vX.Y.Z
   main -> hotfix/X.Y.Z-description -> main and develop -> tag/release vX.Y.Z
   ```

7. Create the development branch that matches the confirmed work type:

   - `feature/X.Y.Z-short-description` from synchronized `develop` for planned functionality or changes;
   - `bugfix/X.Y.Z-short-description` from synchronized `develop` for non-urgent corrections intended for the next release;
   - `hotfix/X.Y.Z-short-description` from synchronized `main` for urgent production corrections.

   In every format, `X.Y.Z` is the version supplied by the user and `short-description` is a concise lowercase kebab-case summary. For example: `bugfix/2.1.2-require-workflow-type`. Reject names with spaces, underscores, uppercase letters, a missing version, or a prefix that does not match the confirmed work type.
8. Preserve the exact version, SemVer impact, and work type supplied by the user throughout the workflow. Use the confirmed version for the final GitHub tag and release. Verify that the version is SemVer-compatible, but never correct, invent, increment, reuse, tag, or publish a version without explicit user confirmation.

9. After a `feature/*` or `bugfix/*` pull request has been successfully merged into `develop`, delete that development branch both locally and from `origin`. Never delete the branch before GitHub confirms that the merge succeeded.

10. Create a temporary `release/X.Y.Z` branch from `develop` to prepare a release. Merge it into both `main` and `develop`, create the confirmed `vX.Y.Z` tag and GitHub Release from `main`, and then delete the release branch locally and from `origin`.
11. Create a temporary `hotfix/X.Y.Z-short-description` branch from `main` for urgent production fixes. Merge it into both `main` and `develop`, create the confirmed `vX.Y.Z` tag and GitHub Release from `main`, and then delete the hotfix branch locally and from `origin`.
12. Never create or use a permanent `releases` branch. Only `main` and `develop` may be permanent.

These checks are required for every new development task, even when the requested change appears small.
