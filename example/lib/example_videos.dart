import 'package:bccm_player/bccm_player.dart';

final exampleVideos = [
  MediaItem(
    // Internet Archive's copy of the full film: h264 Constrained Baseline
    // 640x360 + AAC stereo, ~10min, honours range requests so seeking works.
    //
    // Deliberately a conservative encode. The Google `commondatastorage` bucket
    // that used to host this now 403s, and the obvious replacements (W3C and
    // Blender both mirror the same Peach trailer) are coded at an *odd* width
    // of 853, which the Android emulator's software decoder rejects outright
    // with an IllegalArgumentException from MediaCodec.configure.
    url: 'https://archive.org/download/BigBuckBunny_124/Content/big_buck_bunny_720p_surround.mp4',
    mimeType: 'video/mp4',
    metadata: MediaMetadata(
      title: 'Big Buck Bunny (MP4)',
      artist: 'Blender Foundation',
      artworkUri: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.jpg',
    ),
  ),
  MediaItem(
    // Five-rendition ABR ladder (240p–1080p), so this is the one to reach for
    // when exercising the quality selector.
    url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(
      title: 'Big Buck Bunny (HLS)',
      artist: 'Blender Foundation',
      artworkUri: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.jpg',
    ),
  ),
  MediaItem(
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(title: 'Apple BipBop fMP4 (HLS)'),
  ),
  MediaItem(
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(
      title: 'Apple advanced (HLS/HDR)',
      artist: 'Apple Inc.',
      artworkUri: 'https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.jpg',
    ),
  ),
];
