import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'shizuku_state.dart';

class ShizukuChannel {
  static const _channel = MethodChannel('com.example.dronestuff/shizuku');

  Future<ShizukuState> getShizukuState() async {
    try {
      final result = await _channel.invokeMethod<String>('getShizukuState');
      return ShizukuState.fromString(result ?? 'not_installed');
    } on MissingPluginException {
      return ShizukuState.notInstalled;
    }
  }

  Future<bool> requestShizukuPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestShizukuPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<List<String>> listFiles(String path) async {
    try {
      final result = await _channel.invokeListMethod<String>(
        'listFiles',
        {'path': path},
      );
      return result ?? [];
    } on PlatformException catch (e) {
      throw ShizukuException('listFiles failed: ${e.message}');
    }
  }

  Future<Uint8List> readFile(String path) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>(
        'readFile',
        {'path': path},
      );
      return result ?? Uint8List(0);
    } on PlatformException catch (e) {
      throw ShizukuException('readFile failed: ${e.message}');
    }
  }

  Future<bool> writeFile(String path, Uint8List bytes) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'writeFile',
        {'path': path, 'bytes': bytes},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw ShizukuException('writeFile failed: ${e.message}');
    }
  }

  Future<int> fileSize(String path) async {
    try {
      final result = await _channel.invokeMethod<int>(
        'fileSize',
        {'path': path},
      );
      return result ?? -1;
    } on PlatformException catch (e) {
      throw ShizukuException('fileSize failed: ${e.message}');
    }
  }

  Future<bool> exists(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'exists',
        {'path': path},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw ShizukuException('exists failed: ${e.message}');
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'deleteFile',
        {'path': path},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw ShizukuException('deleteFile failed: ${e.message}');
    }
  }
}

class ShizukuException implements Exception {
  final String message;
  const ShizukuException(this.message);

  @override
  String toString() => 'ShizukuException: $message';
}
