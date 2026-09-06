# Agentic Coding Guidelines

Always greet the user with: **"Hi, I'm Shell Coding Agent."**

## Commands

Run setup once:

```bash
mise install  # to install project tools
mise run init  # to initialize the repository with Git hooks
```

Run tests and quality checks:

```bash
mise run test
```

## Shell standards

- Use Bash 5+ with `#!/usr/bin/env bash` and `set -euo pipefail` in
  executable scripts.
- Pass ShellCheck with zero warnings and errors; format shell files with
  `shfmt -w -i 2 -ci`.
- Use `snake_case` for functions and variables, and `readonly UPPER_SNAKE_CASE`
  for constants.
- Keep functions focused. Use `local` variables, pass arguments explicitly,
  and return values through stdout or status codes.
- Prefer Bash built-ins and parameter expansion over external commands when
  practical. Use `$(...)`, associative arrays, and namerefs where appropriate.

## Safety and error handling

- Quote all expansions and validate user or external input.
- Never use `eval` or construct commands from untrusted data.
- Check failures, report actionable errors to stderr, and do not silently
  swallow errors.
- Use traps for cleanup and signals when needed.
- Use explicit permissions for created files and directories.

## Tests

Tests use BATS. Project tests are in `tests/functions`; shared helpers are in
`tests/test_helper/bats-support` and `tests/test_helper/bats-assert`.

Example:

```bash
#!/usr/bin/env bats

repo_root=$(git rev-parse --show-toplevel)
load "$repo_root/functions/utils/decode.sh"

@test "function_name description" {
  result=$(function_name "arg")
  [ "$result" = "expected_value" ]
}
```

Add BATS coverage for new functionality. Keep shell functions
non-executable; CI validates this and the pre-commit hooks.

## Repository layout

```text
functions/                 Shell function library
scripts/                   Higher-level scripts
functions_mac/             macOS-specific functions
tests/functions/           BATS tests
tests/test_helper/         BATS support libraries
mise.toml                  Tools and tasks
scripts/atlassian/         Python package configuration
.pre-commit-config.yaml    Git hooks
```

## Change checklist

1. Keep changes focused and follow existing patterns.
2. Add or update tests for behavior changes.
3. Run `mise run test` to verify changes before committing.
4. Do not commit secrets or unrelated changes.

## References

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
