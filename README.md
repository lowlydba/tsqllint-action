# TSQLLint Github Action

This action runs the latest [TSQLLint](https://github.com/tsqllint/tsqllint).

## Inputs

### `path`

**Optional** - Space separated path(s) to run linter against.
Wildcards can be specified using `*`.
Default is `*.sql`.

### `config`

**Optional** - Path to a [configuration file](https://github.com/tsqllint/tsqllint#configuration)
for the linter.

### `comment`

**Optional** - Create comment with summary of linter results.

### `only-changed-files`

**Optional** - If run in a pull request, only lint Modified or Added `.sql` files.
Default is `false`.

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

* For pull request comments to work, the job must be triggered by a pull request event type
