# Digital Logic Simulator

A Flutter app for designing and simulating digital logic circuits on a visual canvas.

## Features

- Build circuits with input switches, clocks, logic gates, output bulbs, and display components.
- Connect components with wires and see logic signals update during simulation.
- Load preset circuits and create reusable integrated circuits.
- Use multiple workspaces, with undo and redo for editing.
- Optionally generate circuits from a text description using Gemini.

## Getting started

Install the Flutter SDK, then run:

```sh
flutter pub get
flutter run
```

To run the tests:

```sh
flutter test
```

## Using the editor

Choose a component from the left toolbar and place it on the canvas. Connect component pins to build a circuit, then toggle inputs or use a clock to observe the outputs.

Useful shortcuts: `S` selects the selection tool, `Delete` or `Backspace` removes selected items, `Ctrl+Z` undoes, and `Ctrl+Shift+Z` redoes.

AI circuit generation is optional and requires a Gemini API key, which can be entered in the AI Generate dialog.
