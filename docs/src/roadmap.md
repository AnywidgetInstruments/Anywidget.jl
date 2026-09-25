# Roadmap

Development phases are milestones, numbered `0.0.x` (phase 0 is `0.0.1`);
they are not releases.

## Phase 0 — `0.0.1`: foundations (done)

- Modules from files, URLs or inline source; generic widget; the
  `AbstractAnywidget` interface.
- Messages with binary buffers and a replaceable transport.
- Standalone HTML display and pages.
- Kaimon Slate extension through SlateAFM.

## Phase 1 — `0.0.2`: bidirectional hosts

- Bonito.jl host: operator actions back to Julia, observables per trait.
- Pluto.jl integration (`@bind` through AbstractPlutoDingetjes).
- IJulia comms (Jupyter widget protocol).

## Phase 2 — `0.0.3`: ecosystem

- Loading published anywidgets from PyPI or npm, without Python.
- Registration in the General registry.
