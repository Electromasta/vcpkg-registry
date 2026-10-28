# vcpkg-registry
My vcpkg registry: ports for my own libraries.

| Port | Source |
|---|---|
| commonplusplus | https://git.cranberry-box.com/lewisb3/commonplusplus |

## Using it
In your project's `vcpkg-configuration.json`:
```json
{
    "registries": [
        {
            "kind": "git",
            "repository": "https://git.cranberry-box.com/lewisb3/vcpkg-registry.git",
            "baseline": "<commit of this repo>",
            "packages": ["commonplusplus"]
        }
    ]
}
```
Then depend on it in `vcpkg.json` as usual, e.g. `{ "name": "commonplusplus", "features": ["reflect"] }`.
Everything not listed in `packages` still comes from your microsoft/vcpkg clone at the project's `builtin-baseline`.

To pick up a newer version, bump `baseline` to a newer commit of this repo.

## Releasing a new version
1. Push the change to the library's `master`.
2. `./release.sh <port> <version> <commit-or-ref>`, e.g. `./release.sh commonplusplus 1.1.0 master`
3. `git push`, then bump `baseline` in the projects that should get it.

The script points the port at that commit, sets the version, commits the port, runs `vcpkg x-add-version` to record the version, and commits that. It needs `jq` and `vcpkg` on your PATH.

## Layout
- `ports/<name>/`: `vcpkg.json`, `portfile.cmake`, `usage`
- `versions/baseline.json`: which version each port resolves to at a given commit of this repo
- `versions/<first letter>-/<name>.json`: every released version and the git-tree hash of its port files
