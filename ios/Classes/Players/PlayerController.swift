//
//  PlayerController.swift
//  bccm_player
//
//  Created by Andreas Gangsø on 19/09/2022.
//

import AVFoundation
import Foundation

public protocol PlayerController {
    var id: String { get }
    var mixWithOthers: Bool { get set }
    var manuallySelectedAudioLanguage: String? { get set }
    func setNpawConfig(npawConfig: NpawConfig?)
    func updateAppConfig(appConfig: AppConfig?)
    func getCurrentItem() -> MediaItem?
    func getPlayerTracksSnapshot() -> PlayerTracksSnapshot
    func setSelectedTrack(type: TrackType, trackId: String?)
    func setPlaybackSpeed(_ speed: Float)
    func setVolume(_ speed: Float)
    func setRepeatMode(_ repeatMode: RepeatMode)
    func getPlayerStateSnapshot() -> PlayerStateSnapshot
    func replaceCurrentMediaItem(_ mediaItem: MediaItem, autoplay: NSNumber?, completion: ((FlutterError?) -> Void)?)
    func queueItem(_ mediaItem: MediaItem)
    func play()
    func seekTo(_ positionMs: Int64, _ completion: @escaping (Bool) -> Void)
    func pause()
    func stop(reset: Bool)
    func exitFullscreen()
    func enterFullscreen()
    func hasBecomePrimary()
    func moveQueueItem(from fromIndex: Int, to toIndex: Int)
    func removeQueueItem(id: String)
    func clearQueue()
    func replaceQueueItems(items: [MediaItem], from fromIndex: Int, to toIndex: Int)
    func setCurrentQueueItem(id: String)
    func getQueue() -> MediaQueue
}

/*
 
 public func moveQueueItem(_ playerId: String, from fromIndex: Int, to toIndex: Int, completion: @escaping (FlutterError?) -> Void) {
     let player = getPlayer(playerId)
     player.moveQueueItem(fromIndex, to: toIndex)
     completion(nil)
 }
 
 public func removeQueueItem(_ playerId: String, id: String, completion: @escaping (FlutterError?) -> Void) {
 }
 
 public func clearQueue(_ playerId: String, completion: @escaping (FlutterError?) -> Void) {
 }
 
 public func replaceQueueItems(_ playerId: String, items: [MediaItem], from fromIndex: Int, to toIndex: Int, completion: @escaping (FlutterError?) -> Void) {
 }
 
 public func setCurrentQueueItem(_ playerId: String, id: String, completion: @escaping (FlutterError?) -> Void) {
 }
 
 public func getQueue(_ playerId: String, completion: @escaping (MediaQueue?, FlutterError?) -> Void) {
 }
 
 */
