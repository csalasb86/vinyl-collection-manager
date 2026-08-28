# Security Policy

## Reporting a vulnerability

Please report security issues **privately**, not as a public issue.

Use GitHub's private vulnerability reporting:
[**Report a vulnerability**](https://github.com/csalasb86/vinyl-collection-manager/security/advisories/new).
It opens a private thread visible only to the maintainers.

Useful things to include, as far as you have them: what an attacker could do,
the steps to reproduce it, and the affected version or commit.

This is a personal project, so there is no response-time guarantee. Reports are
read and acted on as soon as reasonably possible.

## Scope

The application itself: the Rails code in this repository and its dependencies.

Out of scope: the Discogs API, and any instance of this app you do not run
yourself. Note that a Discogs personal access token grants access to that
account's collection — treat one as a credential, keep it out of version
control, and revoke it from
[Discogs developer settings](https://www.discogs.com/settings/developers) if it
is ever exposed.

## What is already in place

Security is checked on every push, and CI fails on a finding:

- **Brakeman** — static analysis of the Rails code
- **importmap audit** — known vulnerabilities in pinned JavaScript
- **Dependabot** — alerts and update pull requests for Ruby dependencies
- **bundler-audit** — run locally against the advisory database

Secrets stay out of the repository: `config/master.key` and `.env*` are
gitignored, and only the encrypted `config/credentials.yml.enc` is committed.
