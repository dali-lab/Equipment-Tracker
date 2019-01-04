//
//  File.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 1/3/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import CoreLocation
import FutureKit
import EmitterKit

public final class LocationTracker: NSObject, SingletonClass, CLLocationManagerDelegate {
    private static var _shared: LocationTracker?
    public static var shared: LocationTracker {
        if _shared == nil {
            _shared = LocationTracker()
        }
        return _shared!
    }
    public let locationManager = CLLocationManager()
    public let locationEvent = Event<CLLocation>()
    public let authorizationDeniedEvent = Event<Void>()
    public let authorizationFixedEvent = Event<Void>()
    private var permissionsReqestPromise: Promise<CLAuthorizationStatus>?
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Public API
    
    public func requestPermisions() -> Future<CLAuthorizationStatus> {
        guard permissionsReqestPromise == nil else {
            return permissionsReqestPromise!.future
        }
        
        permissionsReqestPromise = Promise<CLAuthorizationStatus>()
        locationManager.requestAlwaysAuthorization()
        return permissionsReqestPromise!.future
    }
    
    public func start() {
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    public func stop() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            permissionsReqestPromise?.completeWithSuccess(status)
            authorizationFixedEvent.emit(Void())
            break
        case .denied, .restricted:
            permissionsReqestPromise?.completeWithFail("Location authorization was denied or restricted. Location is required on all DALI devices")
            authorizationDeniedEvent.emit(Void())
            break
        case .notDetermined:
            permissionsReqestPromise?.completeWithCancel()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationEvent.emit(locations.first!)
    }
    
    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            authorizationFixedEvent.emit(Void())
        }
    }
    
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        if CLLocationManager.authorizationStatus() == .denied {
            authorizationDeniedEvent.emit(Void())
        }
    }
}
