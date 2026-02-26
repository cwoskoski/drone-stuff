import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/kmz/kmz_parser.dart';
import '../local/local_missions_provider.dart';

final importProvider =
    AsyncNotifierProvider.autoDispose<ImportNotifier, void>(
  ImportNotifier.new,
);

class ImportNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> importKmzFile() async {
    // Capture ref before async gap — provider may be disposed while picker is open
    final repo = ref.read(localMissionRepositoryProvider);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kmz'],
    );

    if (result == null || result.files.isEmpty) return false;

    final file = result.files.first;
    final Uint8List bytes;

    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = File(file.path!).readAsBytesSync();
    } else {
      return false;
    }

    // Validate
    KmzParser.validate(bytes);

    // Store
    await repo.importKmz(bytes, file.name);

    return true;
  }
}
