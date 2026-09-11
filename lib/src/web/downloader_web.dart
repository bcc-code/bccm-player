import 'package:bccm_player/src/downloader_platform_interface.dart';
import 'package:bccm_player/src/pigeon/downloader_pigeon.g.dart';

/// Offline downloads have no web equivalent — there is no background download
/// service and no local storage for HLS segments.
///
/// Without this, [DownloaderInterface.instance] stays [DownloaderNative] and
/// every call fails with a channel error against a pigeon channel that does not
/// exist. Reads answer emptily so a shared "my downloads" UI renders as
/// nothing-downloaded rather than blowing up; anything that would actually
/// start a download fails loudly, because silently doing nothing would be worse.
class DownloaderWeb extends DownloaderInterface {
  @override
  final DownloaderListener events = DownloaderListener();

  @override
  Future<List<Download>> getDownloads() async => const [];

  @override
  Future<Download?> getDownload(String downloadKey) async => null;

  @override
  Future<double> getDownloadStatus(String downloadKey) async => 0;

  @override
  Future<void> removeDownload(String downloadKey) async {}

  @override
  Future<double> getFreeDiskSpace() async => 0;

  @override
  Future<Download> startDownload(DownloadConfig config) =>
      throw UnsupportedError('Downloading is not supported on web.');
}
