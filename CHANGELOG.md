# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking:** `AFMModule` is renamed `FrontendModule`.

### Added

- Documentation: supported Julia versions stated as "1.10 and later, tested on
  1.13" (Kaimon Slate: 1.12 or later); planned work listed with its phase.
- The README and the documentation state that the package is unofficial and
  not affiliated with the anywidget project.

## [0.0.1] - 2026-09-25

Phase 0 of the roadmap: foundations.

### Added

- `AFMModule`: an anywidget front-end module from a local file, a URL or inline
  source, with its stylesheets; `set_asset_base!`.
- `AbstractAnywidget` interface (`afm_module`, `widget_traits`, `message_id`)
  and the generic widget `anywidget(mod; traits...)`.
- `Message`, `encode_buffer` (little-endian, numpy-style dtypes),
  `send_message` and `set_transport!`.
- Standalone HTML display (`text/html`) and `html_page`, each module inlined
  and imported once per page.
- Kaimon Slate package extension (on SlateExtensionsBase): `to_widget` for the
  SlateAFM host shim, served local and inline modules, transport through
  `SlateAFM.afm_emit`.
- Documentation (Documenter.jl, DocumenterLandingPage.jl) with live widgets,
  `llms.txt` and `llms-full.txt`; EARS specification with MoSCoW priorities.

[Unreleased]: https://github.com/s-celles/Anywidget.jl/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/s-celles/Anywidget.jl/releases/tag/v0.0.1
