# NoSEDA roadmap

Updated 2026-10-15. The first priority is a coherent, source-verified definition
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
- [x] Correct all six mod hooks, menu callback tables, module imports/lifetime
  and coexistence guidance.
- [x] Correct engine discovery, alloc/free readiness, optional polls/constructors,
  context ownership and Lua specs/add_params separation.
- [x] Include minimal script, mod and engine+host skeletons in component guides.
- [x] Add `tasks/review.md`: idiom → replacement → risk, evidence and verification.
- [x] Align existing debug/optimize/MIDI guides with the definitions.
- [x] Document sidecar-beta compatibility concerns: user report plus source-verified
  popen write/streaming limitations; do not equate modern with latest beta.
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

- [x] **Priority acceptance run: norns shield with a Raspberry Pi 3** — completed
  2026-10-15 on `10.0.0.138`: Pi 3 B+, shield PCB 200323, update marker 260616,
  modified core `4cbb17f`. Recorded build/hardware, component revision and connected
  devices; started with third-party mods disabled. Results and findings are in the
  [acceptance report](acceptance/2026-10-15-pi3-260616/REPORT.md).
  - [x] Install the three skeletons verbatim from
    `skills/noseda/references/components/{script,mod,engine}.md`; record any edits
    needed to run them as compatibility findings.
  - [x] Check audible output, encoders/keys, repeated start/stop/reset, rerun,
    script/engine switching and cleanup, including partial initialization.
  - [x] Check PARAMS/PSET save/recall, sidecar read/write/delete and missing-data
    defaults; exercise PMAP with injected CCs. No physical controller was connected.
  - [x] Enable only the example mod for its tests: menu entry/exit, state across
    unrelated scripts, disable/restart and shutdown/power-on. Source confirms
    RESTART clears the remembered script; direct SLEEP recall is a follow-up below.
  - [x] Test dirty rendering, menu/modal ownership and native `refresh()` on the
    physical screen; measure cadence instead of assuming 60 Hz delivery.
  - [x] Record idle/playing DSP load, xruns and sequencer lateness under a stated
    workload. Keep firmware and test conditions fixed for Pi 3 comparisons.
  - [x] Save reproducible steps, commands, logs and pass/fail results in the repo;
    distinguish observed behavior from source-derived expectations. Update the
    guides and verification gaps from the results.
- [ ] Repeat the acceptance run on a verifiably unmodified stable monome image
  to establish the stock Pi 3 software baseline; recheck the queued-clock
  cancellation failure there. The completed run used modified core software
  and compiled third-party SC extensions.
- [ ] Verify direct SLEEP from a loaded script recalls it after power-on.
- [ ] Verify PMAP with a physical MIDI controller when available. The three
  skeletons do not require a Grid.
- [ ] Extend the acceptance run to other supported physical norns releases and
  hardware, keeping their results separate from the stock shield/Pi 3 baseline.
- [ ] Assess native refresh on other supported hardware/backends; the tested
  shield's cadence/modal behavior is verified above. Do not infer SDL support.
- [ ] Establish exact affected/fixed builds for reported sidecar-beta failures,
  including popen behavior and any verified workaround. Preserve separate
  source evidence and runtime reports.
- [ ] Verify minimum release versions for APIs used in new examples before
  assigning `norns.version.required` numbers.
- [ ] Maintain representative legacy PSET/PMAP/sidecar migration fixtures.
- [ ] Run end-to-end skill evaluations for creation, legacy review/refactor and
  mod/engine integration; compare outputs against the previous skill.
- [ ] Periodically re-audit source/docs disagreements (PSET actions, mod hooks,
  lattice/LFO defaults, scheduler behavior, shell interfaces).
- [ ] Record maintenance evidence before using “two maintained scripts” to
  justify an idiom unsupported by current core/docs.

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
