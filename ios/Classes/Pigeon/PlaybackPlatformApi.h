// Autogenerated from Pigeon (v22.3.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#import <Foundation/Foundation.h>

@protocol FlutterBinaryMessenger;
@protocol FlutterMessageCodec;
@class FlutterError;
@class FlutterStandardTypedData;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BufferMode) {
  BufferModeStandard = 0,
  BufferModeFastStartShortForm = 1,
};

/// Wrapper for BufferMode to allow for nullability.
@interface BufferModeBox : NSObject
@property(nonatomic, assign) BufferMode value;
- (instancetype)initWithValue:(BufferMode)value;
@end

typedef NS_ENUM(NSUInteger, RepeatMode) {
  RepeatModeOff = 0,
  RepeatModeOne = 1,
};

/// Wrapper for RepeatMode to allow for nullability.
@interface RepeatModeBox : NSObject
@property(nonatomic, assign) RepeatMode value;
- (instancetype)initWithValue:(RepeatMode)value;
@end

typedef NS_ENUM(NSUInteger, PlaybackState) {
  PlaybackStateStopped = 0,
  PlaybackStatePaused = 1,
  PlaybackStatePlaying = 2,
};

/// Wrapper for PlaybackState to allow for nullability.
@interface PlaybackStateBox : NSObject
@property(nonatomic, assign) PlaybackState value;
- (instancetype)initWithValue:(PlaybackState)value;
@end

typedef NS_ENUM(NSUInteger, CastConnectionState) {
  CastConnectionStateNone = 0,
  CastConnectionStateNoDevicesAvailable = 1,
  CastConnectionStateNotConnected = 2,
  CastConnectionStateConnecting = 3,
  CastConnectionStateConnected = 4,
};

/// Wrapper for CastConnectionState to allow for nullability.
@interface CastConnectionStateBox : NSObject
@property(nonatomic, assign) CastConnectionState value;
- (instancetype)initWithValue:(CastConnectionState)value;
@end

typedef NS_ENUM(NSUInteger, TrackType) {
  TrackTypeAudio = 0,
  TrackTypeText = 1,
  TrackTypeVideo = 2,
};

/// Wrapper for TrackType to allow for nullability.
@interface TrackTypeBox : NSObject
@property(nonatomic, assign) TrackType value;
- (instancetype)initWithValue:(TrackType)value;
@end

@class NpawConfig;
@class AppConfig;
@class User;
@class SetUrlArgs;
@class MediaItem;
@class MediaMetadata;
@class MediaQueue;
@class PlayerStateSnapshot;
@class PlayerError;
@class VideoSize;
@class ChromecastState;
@class MediaInfo;
@class PlayerTracksSnapshot;
@class Track;
@class QueueChangedEvent;
@class PrimaryPlayerChangedEvent;
@class PlayerStateUpdateEvent;
@class PositionDiscontinuityEvent;
@class PlaybackStateChangedEvent;
@class PlaybackEndedEvent;
@class PlayerErrorChangedEvent;
@class PictureInPictureModeChangedEvent;
@class MediaItemTransitionEvent;

@interface NpawConfig : NSObject
+ (instancetype)makeWithAppName:(nullable NSString *)appName
    appReleaseVersion:(nullable NSString *)appReleaseVersion
    accountCode:(nullable NSString *)accountCode
    deviceIsAnonymous:(nullable NSNumber *)deviceIsAnonymous;
@property(nonatomic, copy, nullable) NSString * appName;
@property(nonatomic, copy, nullable) NSString * appReleaseVersion;
@property(nonatomic, copy, nullable) NSString * accountCode;
@property(nonatomic, strong, nullable) NSNumber * deviceIsAnonymous;
@end

@interface AppConfig : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithAppLanguage:(nullable NSString *)appLanguage
    audioLanguages:(NSArray<NSString *> *)audioLanguages
    subtitleLanguages:(NSArray<NSString *> *)subtitleLanguages
    analyticsId:(nullable NSString *)analyticsId
    sessionId:(nullable NSNumber *)sessionId;
@property(nonatomic, copy, nullable) NSString * appLanguage;
@property(nonatomic, copy) NSArray<NSString *> * audioLanguages;
@property(nonatomic, copy) NSArray<NSString *> * subtitleLanguages;
@property(nonatomic, copy, nullable) NSString * analyticsId;
@property(nonatomic, strong, nullable) NSNumber * sessionId;
@end

@interface User : NSObject
+ (instancetype)makeWithId:(nullable NSString *)id;
@property(nonatomic, copy, nullable) NSString * id;
@end

@interface SetUrlArgs : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    url:(NSString *)url
    isLive:(nullable NSNumber *)isLive;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, copy) NSString * url;
@property(nonatomic, strong, nullable) NSNumber * isLive;
@end

@interface MediaItem : NSObject
+ (instancetype)makeWithId:(nullable NSString *)id
    url:(nullable NSString *)url
    mimeType:(nullable NSString *)mimeType
    metadata:(nullable MediaMetadata *)metadata
    isLive:(nullable NSNumber *)isLive
    isOffline:(nullable NSNumber *)isOffline
    playbackStartPositionMs:(nullable NSNumber *)playbackStartPositionMs
    lastKnownAudioLanguage:(nullable NSString *)lastKnownAudioLanguage
    lastKnownSubtitleLanguage:(nullable NSString *)lastKnownSubtitleLanguage;
@property(nonatomic, copy, nullable) NSString * id;
@property(nonatomic, copy, nullable) NSString * url;
@property(nonatomic, copy, nullable) NSString * mimeType;
@property(nonatomic, strong, nullable) MediaMetadata * metadata;
@property(nonatomic, strong, nullable) NSNumber * isLive;
@property(nonatomic, strong, nullable) NSNumber * isOffline;
@property(nonatomic, strong, nullable) NSNumber * playbackStartPositionMs;
@property(nonatomic, copy, nullable) NSString * lastKnownAudioLanguage;
@property(nonatomic, copy, nullable) NSString * lastKnownSubtitleLanguage;
@end

@interface MediaMetadata : NSObject
+ (instancetype)makeWithArtworkUri:(nullable NSString *)artworkUri
    title:(nullable NSString *)title
    artist:(nullable NSString *)artist
    durationMs:(nullable NSNumber *)durationMs
    extras:(nullable NSDictionary<NSString *, NSString *> *)extras;
@property(nonatomic, copy, nullable) NSString * artworkUri;
@property(nonatomic, copy, nullable) NSString * title;
@property(nonatomic, copy, nullable) NSString * artist;
@property(nonatomic, strong, nullable) NSNumber * durationMs;
@property(nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> * extras;
@end

@interface MediaQueue : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithItems:(NSArray<MediaItem *> *)items
    currentIndex:(nullable NSNumber *)currentIndex;
@property(nonatomic, copy) NSArray<MediaItem *> * items;
@property(nonatomic, strong, nullable) NSNumber * currentIndex;
@end

@interface PlayerStateSnapshot : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    playbackState:(PlaybackState)playbackState
    isBuffering:(BOOL )isBuffering
    isFullscreen:(BOOL )isFullscreen
    playbackSpeed:(double )playbackSpeed
    videoSize:(nullable VideoSize *)videoSize
    currentMediaItem:(nullable MediaItem *)currentMediaItem
    playbackPositionMs:(nullable NSNumber *)playbackPositionMs
    textureId:(nullable NSNumber *)textureId
    volume:(nullable NSNumber *)volume
    error:(nullable PlayerError *)error;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, assign) PlaybackState playbackState;
@property(nonatomic, assign) BOOL  isBuffering;
@property(nonatomic, assign) BOOL  isFullscreen;
@property(nonatomic, assign) double  playbackSpeed;
@property(nonatomic, strong, nullable) VideoSize * videoSize;
@property(nonatomic, strong, nullable) MediaItem * currentMediaItem;
@property(nonatomic, strong, nullable) NSNumber * playbackPositionMs;
@property(nonatomic, strong, nullable) NSNumber * textureId;
@property(nonatomic, strong, nullable) NSNumber * volume;
@property(nonatomic, strong, nullable) PlayerError * error;
@end

@interface PlayerError : NSObject
+ (instancetype)makeWithCode:(nullable NSString *)code
    message:(nullable NSString *)message;
@property(nonatomic, copy, nullable) NSString * code;
@property(nonatomic, copy, nullable) NSString * message;
@end

@interface VideoSize : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithWidth:(NSInteger )width
    height:(NSInteger )height;
@property(nonatomic, assign) NSInteger  width;
@property(nonatomic, assign) NSInteger  height;
@end

@interface ChromecastState : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithConnectionState:(CastConnectionState)connectionState
    mediaItem:(nullable MediaItem *)mediaItem;
@property(nonatomic, assign) CastConnectionState connectionState;
@property(nonatomic, strong, nullable) MediaItem * mediaItem;
@end

@interface MediaInfo : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithAudioTracks:(NSArray<Track *> *)audioTracks
    textTracks:(NSArray<Track *> *)textTracks
    videoTracks:(NSArray<Track *> *)videoTracks;
@property(nonatomic, copy) NSArray<Track *> * audioTracks;
@property(nonatomic, copy) NSArray<Track *> * textTracks;
@property(nonatomic, copy) NSArray<Track *> * videoTracks;
@end

@interface PlayerTracksSnapshot : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    audioTracks:(NSArray<Track *> *)audioTracks
    textTracks:(NSArray<Track *> *)textTracks
    videoTracks:(NSArray<Track *> *)videoTracks;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, copy) NSArray<Track *> * audioTracks;
@property(nonatomic, copy) NSArray<Track *> * textTracks;
@property(nonatomic, copy) NSArray<Track *> * videoTracks;
@end

@interface Track : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithId:(NSString *)id
    label:(nullable NSString *)label
    language:(nullable NSString *)language
    frameRate:(nullable NSNumber *)frameRate
    bitrate:(nullable NSNumber *)bitrate
    width:(nullable NSNumber *)width
    height:(nullable NSNumber *)height
    downloaded:(nullable NSNumber *)downloaded
    isSelected:(BOOL )isSelected;
@property(nonatomic, copy) NSString * id;
@property(nonatomic, copy, nullable) NSString * label;
@property(nonatomic, copy, nullable) NSString * language;
@property(nonatomic, strong, nullable) NSNumber * frameRate;
@property(nonatomic, strong, nullable) NSNumber * bitrate;
@property(nonatomic, strong, nullable) NSNumber * width;
@property(nonatomic, strong, nullable) NSNumber * height;
@property(nonatomic, strong, nullable) NSNumber * downloaded;
@property(nonatomic, assign) BOOL  isSelected;
@end

@interface QueueChangedEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    queue:(nullable MediaQueue *)queue;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, strong, nullable) MediaQueue * queue;
@end

@interface PrimaryPlayerChangedEvent : NSObject
+ (instancetype)makeWithPlayerId:(nullable NSString *)playerId;
@property(nonatomic, copy, nullable) NSString * playerId;
@end

@interface PlayerStateUpdateEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    snapshot:(PlayerStateSnapshot *)snapshot;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, strong) PlayerStateSnapshot * snapshot;
@end

@interface PositionDiscontinuityEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    playbackPositionMs:(nullable NSNumber *)playbackPositionMs;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, strong, nullable) NSNumber * playbackPositionMs;
@end

@interface PlaybackStateChangedEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    playbackState:(PlaybackState)playbackState
    isBuffering:(BOOL )isBuffering;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, assign) PlaybackState playbackState;
@property(nonatomic, assign) BOOL  isBuffering;
@end

@interface PlaybackEndedEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    mediaItem:(nullable MediaItem *)mediaItem;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, strong, nullable) MediaItem * mediaItem;
@end

@interface PlayerErrorChangedEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    error:(NSString *)error;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, copy) NSString * error;
@end

@interface PictureInPictureModeChangedEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    isInPipMode:(BOOL )isInPipMode;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, assign) BOOL  isInPipMode;
@end

@interface MediaItemTransitionEvent : NSObject
/// `init` unavailable to enforce nonnull fields, see the `make` class method.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)makeWithPlayerId:(NSString *)playerId
    mediaItem:(nullable MediaItem *)mediaItem;
@property(nonatomic, copy) NSString * playerId;
@property(nonatomic, strong, nullable) MediaItem * mediaItem;
@end

/// The codec used by all APIs.
NSObject<FlutterMessageCodec> *nullGetPlaybackPlatformApiCodec(void);

/// The main interface, used by the flutter side to control the player.
@protocol PlaybackPlatformPigeon
- (void)attachWithCompletion:(void (^)(FlutterError *_Nullable))completion;
- (void)newPlayer:(nullable BufferModeBox *)bufferModeBoxed disableNpaw:(nullable NSNumber *)disableNpaw completion:(void (^)(NSString *_Nullable, FlutterError *_Nullable))completion;
- (void)createVideoTexture:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)disposeVideoTexture:(NSInteger)textureId completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)switchToVideoTextureForPlayer:(NSString *)playerId textureId:(NSInteger)textureId completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)disposePlayer:(NSString *)playerId completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)queueMediaItem:(NSString *)playerId mediaItem:(MediaItem *)mediaItem completion:(void (^)(FlutterError *_Nullable))completion;
- (void)updateQueueOrder:(NSString *)playerId itemIds:(NSArray<NSString *> *)items completion:(void (^)(FlutterError *_Nullable))completion;
- (void)moveQueueItem:(NSString *)playerId fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex completion:(void (^)(FlutterError *_Nullable))completion;
- (void)removeQueueItem:(NSString *)playerId id:(NSString *)id completion:(void (^)(FlutterError *_Nullable))completion;
- (void)clearQueue:(NSString *)playerId completion:(void (^)(FlutterError *_Nullable))completion;
- (void)replaceQueueItems:(NSString *)playerId items:(NSArray<MediaItem *> *)items fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex completion:(void (^)(FlutterError *_Nullable))completion;
- (void)setCurrentQueueItem:(NSString *)playerId id:(NSString *)id completion:(void (^)(FlutterError *_Nullable))completion;
- (void)getQueue:(NSString *)playerId completion:(void (^)(MediaQueue *_Nullable, FlutterError *_Nullable))completion;
- (void)replaceCurrentMediaItem:(NSString *)playerId mediaItem:(MediaItem *)mediaItem playbackPositionFromPrimary:(nullable NSNumber *)playbackPositionFromPrimary autoplay:(nullable NSNumber *)autoplay completion:(void (^)(FlutterError *_Nullable))completion;
- (void)setPlayerViewVisibility:(NSInteger)viewId visible:(BOOL)visible error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setPrimary:(NSString *)id completion:(void (^)(FlutterError *_Nullable))completion;
- (void)play:(NSString *)playerId error:(FlutterError *_Nullable *_Nonnull)error;
- (void)seek:(NSString *)playerId positionMs:(double)positionMs completion:(void (^)(FlutterError *_Nullable))completion;
- (void)pause:(NSString *)playerId error:(FlutterError *_Nullable *_Nonnull)error;
- (void)stop:(NSString *)playerId reset:(BOOL)reset error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setVolume:(NSString *)playerId volume:(double)volume completion:(void (^)(FlutterError *_Nullable))completion;
- (void)setRepeatMode:(NSString *)playerId repeatMode:(RepeatMode)repeatMode completion:(void (^)(FlutterError *_Nullable))completion;
- (void)setSelectedTrack:(NSString *)playerId type:(TrackType)type trackId:(nullable NSString *)trackId completion:(void (^)(FlutterError *_Nullable))completion;
- (void)setPlaybackSpeed:(NSString *)playerId speed:(double)speed completion:(void (^)(FlutterError *_Nullable))completion;
- (void)exitFullscreen:(NSString *)playerId error:(FlutterError *_Nullable *_Nonnull)error;
- (void)enterFullscreen:(NSString *)playerId error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setMixWithOthers:(NSString *)playerId mixWithOthers:(BOOL)mixWithOthers completion:(void (^)(FlutterError *_Nullable))completion;
- (void)setNpawConfig:(nullable NpawConfig *)config error:(FlutterError *_Nullable *_Nonnull)error;
- (void)setAppConfig:(nullable AppConfig *)config error:(FlutterError *_Nullable *_Nonnull)error;
- (void)getTracks:(nullable NSString *)playerId completion:(void (^)(PlayerTracksSnapshot *_Nullable, FlutterError *_Nullable))completion;
- (void)getPlayerState:(nullable NSString *)playerId completion:(void (^)(PlayerStateSnapshot *_Nullable, FlutterError *_Nullable))completion;
- (void)getChromecastState:(void (^)(ChromecastState *_Nullable, FlutterError *_Nullable))completion;
- (void)openExpandedCastController:(FlutterError *_Nullable *_Nonnull)error;
- (void)openCastDialog:(FlutterError *_Nullable *_Nonnull)error;
- (void)fetchMediaInfo:(NSString *)url mimeType:(nullable NSString *)mimeType completion:(void (^)(MediaInfo *_Nullable, FlutterError *_Nullable))completion;
- (void)getAndroidPerformanceClassWithCompletion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
@end

extern void SetUpPlaybackPlatformPigeon(id<FlutterBinaryMessenger> binaryMessenger, NSObject<PlaybackPlatformPigeon> *_Nullable api);

extern void SetUpPlaybackPlatformPigeonWithSuffix(id<FlutterBinaryMessenger> binaryMessenger, NSObject<PlaybackPlatformPigeon> *_Nullable api, NSString *messageChannelSuffix);


////////////////// Playback Listener
@interface PlaybackListenerPigeon : NSObject
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger;
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger messageChannelSuffix:(nullable NSString *)messageChannelSuffix;
- (void)onPrimaryPlayerChanged:(PrimaryPlayerChangedEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onPositionDiscontinuity:(PositionDiscontinuityEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onPlayerStateUpdate:(PlayerStateUpdateEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onPlaybackStateChanged:(PlaybackStateChangedEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onPlaybackEnded:(PlaybackEndedEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onMediaItemTransition:(MediaItemTransitionEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onPictureInPictureModeChanged:(PictureInPictureModeChangedEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
- (void)onQueueChanged:(QueueChangedEvent *)event completion:(void (^)(FlutterError *_Nullable))completion;
@end

NS_ASSUME_NONNULL_END
