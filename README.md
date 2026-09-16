# sync-repo

GitHub composite action that copies the checked-out commit's file tree to another repository while creating a new commit with a configurable anonymous identity. The source commit message is preserved; its author, committer, timestamps, signature, and ancestry are not.

Each run creates at most one commit on the target `main` branch. If the target already has the same file tree, the action exits without creating a duplicate commit.

## Usage

```yaml
steps:
  - uses: actions/checkout@v7
    with:
      persist-credentials: false

  - uses: xrdavies/sync-repo@FULL_COMMIT_SHA
    with:
      token: ${{ secrets.TARGET_REPOSITORY_TOKEN }}
      target-repository: target-owner/target-repository
      exclude-path: .github
```

The token needs write access to the target repository. It also needs permission to update workflows when the synchronized tree contains files under `.github/workflows`.

`exclude-path` accepts one repository-relative file or directory. Excluding `.github` prevents source workflows and other GitHub configuration from being copied; excluding `.github/workflows` omits only workflows. Existing target content under the excluded path is removed by the next sync.

Pin this action to a full commit SHA because it receives a write-capable token.

## Test

```sh
./test-sync.sh
```
