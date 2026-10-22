# Architecture

Dependencies point toward `domain`. Concrete adapters are selected in
`core/di/injection.dart`, the application's composition root.

- `domain/entities`: circuit state, component evaluation, and pin geometry.
- `domain/services`: simulation rules and ports for simulation and generation.
- `domain/usecases`: operations that coordinate domain rules and injected ports.
- `data`: HTTP and SQLite adapters, persistence models, and storage.
- `presentation/controllers`: editor interaction, undo history, workspaces, and
  simulation scheduling. Infrastructure enters through provider overrides.
- `presentation/canvas/renderers`: component drawing and text styles. Rendering
  reads entity state without mutating it. `node_renderer.dart` dispatches by type.
- `features/component_library`: bundled asset catalog and editor presets.

`main.dart` loads presets and initializes application dependencies before creating
the widget tree. `LogicDesignerApp` installs a Riverpod `ProviderScope` with
repository/service overrides. Tests supply the same overrides in an isolated
`ProviderContainer`.

## Editor state and responsibilities

`workspaceControllerProvider` owns immutable tab metadata. The
`circuitControllerProvider(workspaceId)` family owns each document's immutable
`CircuitViewState`: selected tool, selected IDs, grid snapping, node/wire counts,
and undo/redo availability. Widgets observe these providers with `ref.watch` and
dispatch actions through `ref.read(provider.notifier)`.

`CircuitController` is the presentation adapter. It guards late callbacks and
publishes UI snapshots; it delegates algorithms to these focused classes:

| Class | Responsibility |
| --- | --- |
| `CircuitDocumentActions` | Node/document edits, undo/redo, loading definitions |
| `EditorInteractionController` | Tools, selection, marquee, hover |
| `WireInteractionController` | Connecting pins and dragging wire segments |
| `NodeMovementController` | Drag accumulation and grid movement |
| `CustomComponentActions` | Export/import, component creation, pin layout |
| `CircuitSession` | Simulation runtime, routing cache, timers, repaint signals |

Domain nodes/pins remain mutable inside the simulation runtime. Hover updates
and simulation ticks update separate `ValueNotifier` repaint signals, avoiding
Riverpod UI snapshots for each frame. The circuit and overlay painters subscribe
to separate signals; hovering only updates the overlay.

Each circuit provider retains itself while its workspace is open, including when
it has no widget listeners. Closing a workspace immediately stops its session and
releases that retention; automatic disposal removes the provider after its last
listener detaches. Late pointer or dialog actions on a closed controller are
ignored. Disposing the application container also releases all sessions and timers.
Switching tabs never closes a session.

All workspaces in one application share a custom-component manager. Independently
constructed application containers have separate custom-component lists. The
production `AppDependencies` object owns its HTTP client; an injected client's lifetime belongs
to its caller. Riverpod dependencies stay in presentation and composition code;
the domain does not depend on Riverpod.

The generation dialog receives `GenerateCircuit`, which validates requests and
parses generated definitions. `CircuitGenerator` hides provider and HTTP details;
`GeminiService` accepts an HTTP client so tests do not need network access.

Circuit entities retain `dart:ui` geometry and colors because layout is part of
the existing canvas format. They contain no Flutter widget or painting code.
Existing map serialization and the definition registry remain for compatibility
with nested IC references and saved files. Compatibility exports at the old
pin-layout, node-factory, and engine paths allow existing consumers to migrate.
New imports should use the domain paths.

When adding a component, implement its state/evaluation in `domain/entities`, add
its deserialization to `domain/factories/node_factory.dart`, its editor creation to
`CreateNodeFactory`, and a presentation renderer plus a dispatch case. Add external
providers through domain interfaces and wire them in the composition root.

Run `flutter test` for dependency boundary checks, simulation and generation
regressions, component rendering, preset round trips, and editor widget tests.
Run `flutter analyze --no-fatal-infos` for static analysis; the existing UI still
contains deprecated API informational notices.
