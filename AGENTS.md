# Repository development rules

Before making any development change in this repository, the agent must:

1. Stop and ask the user for both the exact semantic version in `X.Y.Z` format and the intended change type: `major`, `minor`, or `patch`. Do not infer the change type or calculate, increment, tag, or publish a version automatically. Do not edit files, create a development branch, commit, push, or open a pull request until the user explicitly provides both values.
2. Switch to `main` and synchronize it using:

   ```bash
   git fetch origin
   git pull --ff-only origin main
   ```

3. Confirm that `main` is clean and synchronized. If the working tree is dirty, the pull cannot fast-forward, or synchronization fails, stop and report the problem instead of changing files.
4. Follow the Gitflow promotion model. Only `main` and `develop` are permanent branches:

   ```text
   feature/X.Y.Z-description -> develop\n   develop -> release/X.Y.Z -> main and develop -> tag/release vX.Y.Z\n   main -> hotfix/X.Y.Z-description -> main and develop -> tag/release vX.Y.Z
   ```

5. Create development branches using the exact format `feature/X.Y.Z-short-description`, where `X.Y.Z` is the version supplied by the user and `short-description` is a concise lowercase kebab-case summary. For example: `feature/1.0.1-update-documentation`. Reject names with spaces, underscores, uppercase letters, a missing version, or a prefix other than `feature/`.
6. Use the exact version and change type supplied by the user for the final GitHub tag and release. Verify that they are SemVer-compatible, but never correct, invent, increment, reuse, tag, or publish a version without explicit user confirmation.

7. After a `feature/*` pull request has been successfully merged into `develop`, delete that feature branch both locally and from `origin`. Never delete the branch before GitHub confirms that the merge succeeded.

8. Create a temporary `release/X.Y.Z` branch from `develop` to prepare a release. Merge it into both `main` and `develop`, create the confirmed `vX.Y.Z` tag and GitHub Release from `main`, and then delete the release branch locally and from `origin`.
9. Create a temporary `hotfix/X.Y.Z-short-description` branch from `main` for urgent production fixes. Merge it into both `main` and `develop`, create the confirmed `vX.Y.Z` tag and GitHub Release from `main`, and then delete the hotfix branch locally and from `origin`.
10. Never create or use a permanent `releases` branch. Only `main` and `develop` may be permanent.

These checks are required for every new development task, even when the requested change appears small.
