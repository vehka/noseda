# NoSEDA roadmap

Updated 2026-10-19. Guidance targets the current stable release (260102,
`v2.9.4`); 3.x beta differences live only in `references/tasks/beta-compat.md`.
The first priority is a coherent, source-verified definition
of modern components; additional coverage should follow that definition rather
than accumulating unrelated templates. Keep `SKILL.md` lean and route every
new reference from it.

## Modern baseline — implemented

- [x] Define scripts, mods and engines in `references/modern.md`, with pinned
  norns/monome-docs revisions, path citations and evidence classes.
- [x] Distinguish current core/docs support from a community exemplar's age or
  popularity; record narrowly assigned exemplar purposes.
- [x] Explain script-global isolation versus shared mutations/cached modules;
  remove absolute local-only/global-pollution and private-underscore rules.
- [x] Correct runtime data/PSET paths; distinguish bundled defaults from saves.
- [x] Explain callback defaults, core resets and explicit cleanup ownership.
- [x] Make params/actions/PSET/PMAP the settings integration model; preserve IDs
  and surface migration risks.
- [x] Define actual clock/metro time domains, transport policy, lattice sprockets,
  sequins and event-recording choices. Correct sync catch-up and note units.
- [x] Add foundational UI patterns: dirty screen/grid cadence, menu/modal ownership,
  shipped helpers, documented exceptions and source-only native refresh.
- [x] Add foundational state patterns: startup recall, PSET hooks, versioned
  sidecars, absent-data policy and session boundaries.
- [x] Correct the mod hooks (five on stable), menu callback tables, module imports/lifetime
  and coexistence guidance.
- [x] Correct engine discovery, alloc/free readiness, optional polls/constructors,
  context ownership and Lua specs/add_params separation.
- [x] Include minimal script, mod and engine+host skeletons in component guides.
- [x] Add `tasks/review.md`: idiom → replacement → risk, evidence and verification.
- [x] Align existing debug/optimize/MIDI guides with the definitions.
- [x] Re-pin source citations from upstream HEAD (3.x beta) to stable `v2.9.4`;
  move beta-only material (sidecar shell, routing hook, services, beta hardware
  observations) into opt-in `tasks/beta-compat.md`. Done 2026-10-19.
- [x] Update entry-point routing and README.

### Validation completed for this revision

- [x] Check local Markdown links/anchors, frontmatter/name/description length,
  reference routing and lean entry-point length.
- [x] Parse all 14 Lua example blocks with `luac5.3`.
- [x] Exercise script transport/dirty redraw/PSET actions, mod menu and persistent
  module state, engine Lua host controls, sidecar default/read/delete paths and
  MIDI note ownership with upstream Lua libraries and scoped host primitives.
- [x] Compile the engine class alongside upstream Crone classes with sclang,
  and build its SynthDef graph without booting an audio server.

These are static and host-instrumented checks, not a desktop norns session,
physical-device audio test or sidecar-beta regression reproduction.

## Verification and compatibility

- [ ] **Priority: acceptance run on a verifiably unmodified stable image**
  (260102) on a Pi 3 shield, repeating the beta run's procedure
  (`acceptance/2026-10-15-pi3-260616-beta/`). Establish the stock baseline:
  skeletons verbatim, sound/controls, PSET/PMAP/sidecar, mod lifecycle, native
  `refresh()` cadence and modal behavior, DSP load/xruns/lateness. Recheck the
  queued-clock cancellation failure there (same Lua/scheduler code as the beta).
- [ ] Verify direct SLEEP from a loaded script recalls it after power-on.
- [ ] Verify PMAP with a physical MIDI controller when available. The three
  skeletons do not require a Grid.
- [ ] Extend the acceptance run to other supported hardware (CM3 norns,
  Pi 4 shield), keeping results separate from the shield/Pi 3 baseline.
- [ ] Assess native refresh on other supported hardware/backends. Do not infer
  SDL support.
- [ ] Verify minimum release versions for APIs used in new examples before
  assigning `norns.version.required` numbers.
- [ ] Maintain representative legacy PSET/PMAP/sidecar migration fixtures.
- [ ] Run end-to-end skill evaluations for creation, legacy review/refactor and
  mod/engine integration; compare outputs against the previous skill.
- [ ] Periodically re-audit source/docs disagreements (PSET actions, mod hooks,
  lattice/LFO defaults, scheduler behavior) and re-pin when stable changes.
- [ ] Record maintenance evidence before using “two maintained scripts” to
  justify an idiom unsupported by current core/docs.

## Beta compatibility (3.x)

Separate from the stable guidance; used only when explicitly requested or for
beta-only failures and core work.

- [x] **Beta acceptance run: Pi 3 shield at 260616 (v3.0.1)** — completed
  2026-10-15 on `10.0.0.138`: Pi 3 B+, shield PCB 200323, modified core
  `4cbb17f`. Skeletons ran verbatim; results in the
  [acceptance report](acceptance/2026-10-15-pi3-260616-beta/REPORT.md),
  summarized in `beta-compat.md`.
- [ ] Establish exact affected/fixed builds for the reported `io.popen` failure
  (lua_shell arrived in v3.0.2 / 260819), and a verified workaround.
- [ ] Beta-compatibility recipes for common subprocess uses (directory listing,
  long-running helpers, popen write mode) with checks on a beta device.
- [ ] Re-pin `B` when a new beta is released; track when beta changes reach stable.

## Focused pattern expansion

### UI and input

Foundational redraw/modal guidance is complete in `patterns/ui.md`; this is not
yet an exhaustive UI design or input reference.

- [ ] Layout strategies for 128×64, fonts, visualization and graph helpers.
- [ ] Multi-page navigation, lists and widget integration examples.
- [ ] Encoder accumulation/acceleration and context-sensitive controls.
- [ ] Key combinations, held modifiers and input-mode transitions.
- [ ] Animation designs with measured rendering budgets.

### Timing and recorded performance

`patterns/timing.md` covers current clock/metro/lattice/sequence semantics.
Lattice is a **clocked timing framework**, not a grid framework.

- [ ] Annotated multi-sprocket sequencer with swing and source-aware transport.
- [ ] Pattern-time versus reflection migration, including saved-recording fixtures.
- [ ] Tempo/subdivision changes and quantized launch policy examples.
- [ ] LFO/timeline integration when the actual task needs them.

### State and sessions

`patterns/state.md` covers PSET recall and sidecars, not a complete session manager.

- [ ] Instrument-specific schema migrations and compatible save import.
- [ ] Audio-inclusive session snapshots and multi-file commit/recovery policy.
- [ ] Undo/redo for musical edits.
- [ ] Session selection and shared-library persistence contracts.

### Audio and devices

- [ ] Softcut recording/playback, buffers, fades and routing patterns.
- [ ] Audio file selection/loading and project-specific audio ownership.
- [ ] MIDI input, multi-port selection/hotplug and clock-source integration.
- [ ] Broader PMAP/controller recipes beyond note bookkeeping.
- [ ] Grid connection/layout, dirty rendering, multi-grid and reconnect behavior.
- [ ] Arc ring rendering, deltas and multi-device use.
- [ ] Crow CV/gates, input monitoring, clock ownership and cleanup.
- [ ] HID, keyboard/gamepad and serial examples where supported.

## Advanced components and reusable libraries

- [ ] Larger script architecture: injected musical actions, UI separation,
  reusable modules and compatibility-preserving refactors.
- [ ] Engine selection/shared voice packaging and cross-component contracts.
- [ ] Mod settings persistence, safe wrapper composition, parameter injection
  and inter-mod APIs with real lifecycle tests.
- [ ] Complete optional nb voice-provider example with backend capability and
  held-note/selection/panic tests.
- [ ] Engine polyphony, voice stealing, sample/buffer ownership, effects and
  modulation with measured hardware headroom.
- [ ] Focused `musicutil`, util/tabutil, UI/graph and container recipes when
  current public references don't already answer the task.
- [ ] Music-theory/generative examples: scales/chords/tuning, Euclidean rhythms,
  L-systems, probability and related algorithms.
- [ ] DSP examples with commands, specs, resource lifecycle and measured sound/CPU
  tradeoffs rather than generic UGen efficiency claims.

## Testing, packaging and workflows

- [ ] Reusable test boundaries/mocks for meaningful script behavior; keep host
  binding, audio and firmware regressions distinct from offline Lua checks.
- [ ] Integration checks for notes, transport, PSETs, device hotplug and partial init.
- [ ] More hardware performance baselines with repeatable conditions and reports.
- [ ] Annotated sampler, MIDI processor, generative instrument and multi-page UI.
- [ ] Extended utility/router/recorder mod examples.
- [ ] Polyphonic, FM, sample-player and effect engine examples.
- [ ] Creation/enhancement/release workflows beyond the component skeletons;
  `tasks/review.md` already covers review/refactor, so avoid a duplicate checklist.
- [ ] Distribution/versioning/dependency and backwards-compatibility examples.
- [ ] Cross-script/service and ecosystem integrations only with verified contracts.

## Existing tooling

- [x] REPL client and network/desktop debugging guidance.
- [x] Before/after performance procedure, internal diagnostic labels and ownership
  checks, with version-sensitive scheduler semantics.
- [x] MIDI note-off bookkeeping/capture guidance and parameter collision checks.

Keep future guidance concise, link to primary evidence, and state what was
actually run. Desktop correctness is useful; physical-device timing, audio,
controls and beta compatibility require their own verification.
