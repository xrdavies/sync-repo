# sync-repo

GitHub composite action that copies the checked-out commit's file tree to another repository while creating a new commit with a configurable anonymous identity. The source commit message is preserved; its author, committer, timestamps, signature, and ancestry are not.

Each run creates at most one commit on the target `main` branch. If the target already has the same file tree, the action exits without creating a duplicate commit.

## Usage

```yaml
steps:
  - uses: actions/checkout@v7
    with:
      persist-credentials: false

  - uses: xrdavies/sync-repo@v1.0.0
    with:
      token: ${{ secrets.TARGET_REPOSITORY_TOKEN }}
      target-repository: target-owner/target-repository
      exclude-path: .github
```

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `token` | Yes | | Token with write access to the target repository |
| `target-repository` | Yes | | Target repository in `owner/name` format |
| `exclude-path` | No | | One repository-relative file or directory to omit |
| `author-name` | No | `repository-sync` | Author and committer name for target commits |
| `author-email` | No | `repository-sync@users.noreply.github.com` | Author and committer email for target commits |

The target repository must already exist. The action writes anonymous snapshot commits to its `main` branch and does not preserve source authors, timestamps, signatures, or ancestry. Repeated runs with the same target tree do not create duplicate commits.

The token needs Contents write access to the target repository. It also needs permission to update workflows when the synchronized tree contains files under `.github/workflows`.

`exclude-path` accepts one repository-relative file or directory. Excluding `.github` prevents source workflows and other GitHub configuration from being copied; excluding `.github/workflows` omits only workflows. Existing target content under the excluded path is removed by the next sync.

Use an exact release such as `v1.0.0`; do not reference `main`.

## Test

```sh
./test-sync.sh
```
