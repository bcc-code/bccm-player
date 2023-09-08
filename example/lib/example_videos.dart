import 'package:bccm_player/bccm_player.dart';

final exampleVideos = [
  MediaItem(
    url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    mimeType: 'video/mp4',
    metadata: MediaMetadata(
      title: 'Big Buck Bunny (MP4)',
      artist: 'Blender Foundation',
      artworkUri: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
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
      artworkUri: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
    ),
  ),
  MediaItem(
    url:
        'https://vod2.stream.brunstad.tv/out/v1/d82e5f518ec5447a93b26a6c0322c848/ab9e7540a3e34bee86ec6af8c7cdc342/1467e3c2761c4947ae7dc7a6c162747f/index.m3u8?EncodedPolicy=Policy%3DeyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly92b2QyLnN0cmVhbS5icnVuc3RhZC50di9vdXQvdjEvZDgyZTVmNTE4ZWM1NDQ3YTkzYjI2YTZjMDMyMmM4NDgvYWI5ZTc1NDBhM2UzNGJlZTg2ZWM2YWY4YzdjZGMzNDIvKiIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTY5NDEwMjQ4M319fV19%26Signature%3DadKvAzhaTzeAmq3145MhIbIh2CWQyCvtpzG0h21ypXPMBObPWygtVCvJyFJ4TtrQAcv7~Xe6nzqZ74vspDEG7Pj7J5SA2wnOvufJxe1xB4aILAglLyS4~g8JAOWgQi6SBb6UJ1mqUQE9H4o2rPMhIo8zOnotgmyb2Da2wObDKbRNCovfoNhT85ZZz66KEkKVO89Kc~WVTxk5-rr8dtG3pGFnzAmeQ4vIQGBdPhF4pcNOAjI5gxozqiqbmrp8kkj28pxvVei3ocgOhVviGWG4iNx9fO14M7S0cR1exQ-78lBCMH-9dDaIadAmiHlq6xXzdnfivIL14HVfGJbDgqjFqg__%26Key-Pair-Id%3DKUAUGK7DA5ZYE',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(title: 'bcc (HLS)'),
  ),
  MediaItem(
    url:
        'https://vod2.stream.brunstad.tv/out/v1/880da581df2d414fbf420e636e1ce5ce/ab9e7540a3e34bee86ec6af8c7cdc342/1467e3c2761c4947ae7dc7a6c162747f/index.m3u8?EncodedPolicy=Policy%3DeyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly92b2QyLnN0cmVhbS5icnVuc3RhZC50di9vdXQvdjEvODgwZGE1ODFkZjJkNDE0ZmJmNDIwZTYzNmUxY2U1Y2UvYWI5ZTc1NDBhM2UzNGJlZTg2ZWM2YWY4YzdjZGMzNDIvKiIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTY5NDExOTU4Nn19fV19%26Signature%3DZ9pbIooisYtOMdF~4UCI~XCtgZ461ewmjq1TZIc4L0JyoT7sMXMvsSJQyYcZI91s6RlzizUyW64fcrh3KnEBQtdz-fAlFdg8JHLgOduNezxGBNKfr7yf506rhT0Q-tl5TTRKASzNjynCKRqroiRVLobNqumNS68irfP7mfO1ohmpSLBtv7NHzgXhCDDqQ2TPvPvOOHPg5aWhjzrq59UpZde-gWpjraI-8EoHs4S5uXAd-fQLXXYBGsMI-tMtVz6vStbIykjKg9Lqe5wXdYnPTHYx89r7wE5UmH2njgPmR1A9UqXoodiC3HTTIEV-0-dC~tXUzyvXnM-fSC7PWgXYWA__%26Key-Pair-Id%3DKUAUGK7DA5ZYE',
    mimeType: 'application/x-mpegURL',
    metadata: MediaMetadata(title: 'bcc short (HLS)'),
  )
];
