# Architecture

Dependencies point toward `domain`. Concrete adapters are selected in
`core/di/injection.dart`, the application's composition root.

- `domain/entities`: circuit state, component evaluation, and pin geometry.
- `domain/services`: simulation rules and ports for simulation and generation.
- `domain/usecases`: operations that coordinate domain rules and injected ports.
- `data`: HTTP and SQLite adapters, persistence models, and storage.
- `presentation/controllers`: editor interaction, undo history, workspaces, and
  simulation scheduling. Infrastructure dependencies are constructor arguments.
- `presentation/canvas/renderers`: component drawing and text styles. Rendering
  reads entity state without mutating it. `node_renderer.dart` dispatches by type.
- `features/component_library`: bundled asset catalog and editor presets.

`main.dart` loads presets and initializes application dependencies before creating
the widget tree. Workspaces receive a controller factory. Each workspace owns its
simulation service and disposes its timer; all workspaces in one application
share a custom-component manager. Independently constructed application containers
have separate custom-component lists. The production container owns its HTTP
client; an injected client's lifetime belongs to its caller.

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
