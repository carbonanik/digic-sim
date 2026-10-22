import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Domain does not import outer layers or Flutter widgets', () {
    for (final file
        in Directory('lib/domain')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final imports = RegExp(
        r'''(?:import|export)\s+['"]([^'"]+)['"]''',
      ).allMatches(file.readAsStringSync());
      for (final match in imports) {
        final target = match[1]!;
        if (target.startsWith('dart:')) continue;
        final resolved = target.startsWith('package:')
            ? target
            : file.absolute.uri.resolve(target).path;
        expect(
          resolved,
          contains('/domain/'),
          reason: '${file.path} depends on $target',
        );
      }
    }
  });

  test('Presentation does not import infrastructure implementations', () {
    for (final file
        in Directory('lib/presentation')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final imports = RegExp(
        r'''import\s+['"]([^'"]+)['"]''',
      ).allMatches(file.readAsStringSync());
      for (final match in imports) {
        final target = match[1]!;
        final resolved = target.startsWith('package:')
            ? target
            : file.absolute.uri.resolve(target).path;
        expect(
          resolved,
          isNot(contains('/data/')),
          reason: '${file.path} depends on $target',
        );
        expect(
          resolved,
          isNot(contains('/simulation/')),
          reason: '${file.path} depends on $target',
        );
      }
    }
  });
}
