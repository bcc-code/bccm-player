//
//  DownloaderError.swift
//  bccm_player
//
//  Created by Coen Jan Wessels on 05/09/2023.
//

public enum DownloaderError : Error, FlutterErrorConvertible {
    case invalidUrl(url: String)
    case unknownDownloadKey(key: String)
    
    public var flutterError: FlutterError {
        switch (self) {
        case .invalidUrl(url: _): return FlutterError() // TODO: Error message
        default: return FlutterError() // TODO: Error message
        }
    }
}
