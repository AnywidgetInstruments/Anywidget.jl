# Security policy

## Supported versions

Anywidget.jl is pre-alpha: only the latest version on the `main`
branch receives security fixes.

## Reporting a vulnerability

Please do **not** open a public issue for a security problem.

Report it privately through a
[GitHub Security Advisory](https://github.com/AnywidgetInstruments/Anywidget.jl/security/advisories/new)
(GHSA) of this repository. Include the version (package and Julia), the steps to reproduce, and the
impact you expect.

You should receive an answer within 7 days. Once a fix is ready, the advisory
is published with credit to the reporter, unless they prefer otherwise.

## Scope

Anywidget.jl runs front-end modules chosen by the user. A module given by URL
is fetched and executed by the browser: only use modules you trust.
