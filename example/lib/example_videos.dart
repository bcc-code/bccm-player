import 'package:bccm_player/bccm_player.dart';

final exampleVideos = [
  MediaItem(
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    mimeType: 'video/mp4',
    metadata: MediaMetadata(title: 'Big Buck Bunny (MP4)'),
  ),
  MediaItem(
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(title: 'Apple BipBop fMP4 (HLS)'),
  ),
  MediaItem(
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(title: 'Apple advanced (HLS/HDR)'),
  ),
];
