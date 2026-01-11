import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FfmpegRuntimeManager {
  static const version = '4.4.1';

  Future<FfmpegRuntimeInfo> status() async {
    final dir = await _runtimeDir();
    final ffmpegPath = p.join(dir.path, _ffmpegBinaryName());
    final ffprobePath = p.join(dir.path, _ffprobeBinaryName());
    final ffmpegExists = await File(ffmpegPath).exists();
    final ffprobeExists = await File(ffprobePath).exists();
    return FfmpegRuntimeInfo(
      isInstalled: ffmpegExists && ffprobeExists,
      ffmpegPath: ffmpegExists ? ffmpegPath : null,
      ffprobePath: ffprobeExists ? ffprobePath : null,
    );
  }

  Future<FfmpegRuntimeInfo> install({
    void Function(double progress)? onProgress,
  }) async {
    final targetDir = await _runtimeDir();
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final ffmpeg = _ffmpegArtifact();
    final ffprobe = _ffprobeArtifact();

    await _downloadAndExtract(
      ffmpeg,
      targetDir,
      onProgress: (progress) => onProgress?.call(progress * 0.5),
    );
    await _downloadAndExtract(
      ffprobe,
      targetDir,
      onProgress: (progress) => onProgress?.call(0.5 + progress * 0.5),
    );

    return status();
  }

  Future<void> _downloadAndExtract(
    _FfmpegArtifact artifact,
    Directory targetDir, {
    void Function(double progress)? onProgress,
  }) async {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      artifact.url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    final digest = sha256.convert(bytes).toString();
    if (digest != artifact.sha256) {
      throw FfmpegRuntimeException('Checksum mismatch for ${artifact.url}.');
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      if (!file.isFile || file.name != artifact.binaryName) {
        continue;
      }
      final outFile = File(p.join(targetDir.path, artifact.binaryName));
      final content = file.content as List<int>;
      await outFile.writeAsBytes(content, flush: true);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', outFile.path]);
      }
    }
  }

  Future<Directory> _runtimeDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory(
      p.join(base.path, 'reddit_dl', 'ffmpeg', version, _platformKey()),
    );
  }

  _FfmpegArtifact _ffmpegArtifact() {
    final platform = _platformKey();
    return _FfmpegArtifact(
      url:
          'https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v$version/ffmpeg-$version-$platform.zip',
      sha256: _ffmpegChecksums[platform]!,
      binaryName: _ffmpegBinaryName(),
    );
  }

  _FfmpegArtifact _ffprobeArtifact() {
    final platform = _platformKey();
    return _FfmpegArtifact(
      url:
          'https://github.com/ffbinaries/ffbinaries-prebuilt/releases/download/v$version/ffprobe-$version-$platform.zip',
      sha256: _ffprobeChecksums[platform]!,
      binaryName: _ffprobeBinaryName(),
    );
  }

  String _ffmpegBinaryName() {
    return Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  }

  String _ffprobeBinaryName() {
    return Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';
  }

  String _platformKey() {
    if (Platform.isMacOS) {
      return 'osx-64';
    }
    if (Platform.isWindows) {
      return 'win-64';
    }
    return 'linux-64';
  }
}

class FfmpegRuntimeInfo {
  const FfmpegRuntimeInfo({
    required this.isInstalled,
    required this.ffmpegPath,
    required this.ffprobePath,
  });

  final bool isInstalled;
  final String? ffmpegPath;
  final String? ffprobePath;
}

class FfmpegRuntimeException implements Exception {
  FfmpegRuntimeException(this.message);

  final String message;

  @override
  String toString() => 'FfmpegRuntimeException: $message';
}

class _FfmpegArtifact {
  const _FfmpegArtifact({
    required this.url,
    required this.sha256,
    required this.binaryName,
  });

  final String url;
  final String sha256;
  final String binaryName;
}

const _ffmpegChecksums = {
  'osx-64': 'e08c670fcbdc2e627aa4c0d0c5ee1ef20e82378af2f14e4e7ae421a148bd49af',
  'win-64': 'd1124593b7453fc54dd90ca3819dc82c22ffa957937f33dd650082f1a495b10e',
  'linux-64':
      '4348301b0d5e18174925e2022da1823aebbdb07282bbe9adb64b2485e1ef2df7',
};

const _ffprobeChecksums = {
  'osx-64': '4c0089e9526f991a9fb31ab6c4491bddea0fc7af363f27747e91db052081d711',
  'win-64': 'c715d3c4435726e1cb8844fe88d65ec920761ef7e890c44bb03be2897d0408ab',
  'linux-64':
      '4f4e1908060233b11feeb854135c603ccb29077931ff2567a4741b90897ef808',
};
