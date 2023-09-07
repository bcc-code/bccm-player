//
//  TrackUtils.swift
//  bccm_player
//
//  Created by Andreas Gangsø on 07/09/2023.
//

import AVFoundation
import Foundation

class TrackUtils {
    static func getAudioTracksForAsset(_ asset: AVAsset, playerItem: AVPlayerItem?) -> [Track] {
        var audioTracks: [Track] = []
        if let audioGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            for (index, option) in audioGroup.options.enumerated() {
                let track = Track.make(withId: "\(index)",
                                       label: option.displayName,
                                       language: option.locale?.identifier,
                                       frameRate: nil,
                                       bitrate: nil,
                                       width: nil,
                                       height: nil,
                                       isSelected: playerItem == nil ? false : NSNumber(value: playerItem!.currentMediaSelection.selectedMediaOption(in: audioGroup) == option))
                audioTracks.append(track)
            }
        }
        return audioTracks
    }

    static func getTextTracksForAsset(_ asset: AVAsset, playerItem: AVPlayerItem?) -> [Track] {
        var textTracks: [Track] = []
        if let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            for (index, option) in subtitleGroup.options.enumerated() {
                let track = Track.make(withId: "\(index)",
                                       label: option.displayName,
                                       language: option.locale?.identifier,
                                       frameRate: nil,
                                       bitrate: nil,
                                       width: nil,
                                       height: nil,
                                       isSelected: NSNumber(value: playerItem == nil ? false : playerItem!.currentMediaSelection.selectedMediaOption(in: subtitleGroup) == option))
                textTracks.append(track)
            }
        }
        return textTracks
    }

    static func getVideoTracksForAsset(_ asset: AVAsset, playerItem: AVPlayerItem?) -> [Track] {
        var videoTracks: [Track] = []
        let urlAsset = asset as? AVURLAsset
        if #available(iOS 15, *), let urlAsset = urlAsset {
            let variants = urlAsset.variants
            for variant in variants {
                guard let bitrate = variant.averageBitRate,
                      let width = variant.videoAttributes?.presentationSize.width,
                      let height = variant.videoAttributes?.presentationSize.height,
                      let frameRate = variant.videoAttributes?.nominalFrameRate
                else {
                    continue
                }
                let currentPreferredBitrate = playerItem?.preferredPeakBitRate
                let track = Track.make(withId: "\(Int(bitrate))",
                                       label: "\(Int(width)) x \(Int(height))",
                                       language: nil,
                                       frameRate: frameRate as NSNumber,
                                       bitrate: Int(bitrate) as NSNumber,
                                       width: Int(width) as NSNumber,
                                       height: Int(height) as NSNumber,
                                       isSelected: (currentPreferredBitrate != nil && Int(currentPreferredBitrate!) == Int(bitrate)) as NSNumber)
                videoTracks.append(track)
            }
        }
        return videoTracks
    }
}

extension AVPlayerItem {
    func setAudioLanguage(_ audioLanguage: String) -> Bool {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible) {
            let locale = Locale(identifier: audioLanguage)
            let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            if let option = options.first {
                select(option, in: group)
                return true
            }
        }
        return false
    }

    func setSubtitleLanguage(_ subtitleLanguage: String) -> Bool {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
            let locale = Locale(identifier: subtitleLanguage)
            let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            if let option = options.first {
                select(option, in: group)
                return true
            }
        }
        return false
    }

    func getSelectedAudioLanguage() -> String? {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible),
           let selectedOption = currentMediaSelection.selectedMediaOption(in: group),
           let languageCode = selectedOption.extendedLanguageTag
        {
            return languageCode
        }

        return nil
    }

    func getSelectedSubtitleLanguage() -> String? {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible),
           let selectedOption = currentMediaSelection.selectedMediaOption(in: group),
           let languageCode = selectedOption.extendedLanguageTag
        {
            return languageCode
        }

        return nil
    }
}
