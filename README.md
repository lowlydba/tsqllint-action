# TSQLLint GitHub Action

[![Lint](https://github.com/lowlydba/tsqllint-action/actions/workflows/lint.yml/badge.svg)](https://github.com/lowlydba/tsqllint-action/actions/workflows/lint.yml)
[![Integration Tests](https://github.com/lowlydba/tsqllint-action/actions/workflows/test.yml/badge.svg)](https://github.com/lowlydba/tsqllint-action/actions/workflows/test.yml)

This action runs the latest [TSQLLint](https://github.com/tsqllint/tsqllint).

## Inputs

### `path`

**Optional** - Space separated path(s) to run linter against.
Wildcards can be specified using `*`.
Default is `*.sql`.

### `config`

**Optional** - Path to a [configuration file](https://github.com/tsqllint/tsqllint#configuration)
for the linter.
Default is `.github/linters/.tsqllintrc`

### `comment`

**Optional** - Create comment with summary of linter results.
Default is `false`.

### `only-changed-files`

**Optional** - If run in a pull request, only lint Modified or Added files.
Default is `false`.

### `append-comment`

**Optional** - Append results from multiple runs in a single comment if `comment` is also `true`.
Default is `false`.

### `summary`

**Optional** - Add linter results to the job summary.
Default is `false`.

### `compare-branch`

**Optional** - Branch to diff against when using `only-changed-files`.
Default is `main`.

## Examples

```yml
jobs:
  build:
    name: Lint Code
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3.0.2

      - name: TSQLLint
        uses: lowlydba/tsqllint-action@v1.0.0
        with:
          path: "*.sql *.tsql"
          config: "./.github/linter-conf/.tsqllintrc_150"
          comment: true
```

## Notes

* If using `append`, running [marocchino/sticky-pull-request-comment][sticky-pull-request] first with the `delete` parameter may be required.
See the test workflow as an example.

[sticky-pull-request]: https://github.com/marocchino/sticky-pull-request-comment
