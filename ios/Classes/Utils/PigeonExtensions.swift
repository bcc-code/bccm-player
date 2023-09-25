//
//  PigeonExtensions.swift
//  bccm_player
//
//  Created by Andreas Gangsø on 19/06/2023.
//

import AVKit
import Foundation

extension TrackType {
    func asAVMediaCharacteristic() -> AVMediaCharacteristic? {
        if self == .audio {
            return .audible
        } else if self == .text {
            return .legible
        } else if self == .video {
            return .visual
        } else {
            return nil
        }
    }
}

extension MediaMetadata {
    /// Because swift crashes when reading a NSDictionary<String *, String *> with null values
    func safeExtras() -> [String: Any]? {
        value(forKey: "extras") as? [String: Any]
    }
}

extension FlutterError: Error {}

/**
        Helper function for catching Swift errors and returing the tuple format, Flutter pigeon requires.

        For all other errors, it will generate a default FlutterError, based on the description of the error.
 */
public func returnFlutterResult<T>(_ exec: () async throws -> T?) async -> (T?, FlutterError?) {
    do {
        return try await (exec(), nil)
    } catch let error as FlutterError {
        return (nil, error)
    } catch {
        return (nil, FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
    }
}

public func returnFlutterResult(_ exec: () async throws -> ()) async -> FlutterError? {
    do {
        try await exec()
    } catch let error as FlutterError {
        return error
    } catch {
        return FlutterError(code: "unknown", message: error.localizedDescription, details: nil)
    }

    return nil
}

public func returnFlutterResult<InputValue>(_ exec: () async throws -> InputValue) async -> (InputValue.Value?, FlutterError?)
    where InputValue: FlutterValueConvertible
{
    await returnFlutterResult<InputValue.Value> { try await exec().flutterValue }
}

public protocol FlutterValueConvertible {
    associatedtype Value

    var flutterValue: Value { get }
}

extension Double: FlutterValueConvertible {
    public typealias Value = NSNumber

    public var flutterValue: NSNumber {
        NSNumber(value: self)
    }
}
