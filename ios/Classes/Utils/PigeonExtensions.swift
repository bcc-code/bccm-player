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

/**
        Helper function for catching Swift errors and returing the tuple format, Flutter pigeon requires.
 
        When a error is catched that implements the protocol `FlutterErrorConvertible`,
        The error will be converted using `flutterError`

        For all other errors, it will generate a default FlutterError, based on the description of the error.
 */
public func returnFlutterResult<T>(_ exec: () async throws -> T?) async -> (T?, FlutterError?) {
    do {
        return await (try exec(), nil)
    } catch let error as FlutterErrorConvertible {
        return (nil, error.flutterError)
    } catch {
        return (nil, FlutterError()) // TODO: Error message
    }
}

public func returnFlutterResult(_ exec: () async throws -> ()) async -> FlutterError? {
    do {
        try await exec()
    } catch let error as FlutterErrorConvertible {
        return error.flutterError
    } catch {
        return FlutterError() // TODO: Error message
    }
    
    return nil
}

public func returnFlutterResult<InputValue>(_ exec: () async throws -> InputValue) async -> (InputValue.Value?, FlutterError?)
    where InputValue : FlutterValueConvertible {
        await returnFlutterResult<InputValue.Value> { try await exec().flutterValue }
}

public protocol FlutterErrorConvertible {
    var flutterError: FlutterError { get }
}

public protocol FlutterValueConvertible {
    associatedtype Value
    
    var flutterValue: Value { get }
}

extension Double : FlutterValueConvertible {
    public typealias Value = NSNumber
    
    public var flutterValue: NSNumber {
        NSNumber(value: self)
    }
}
