//
//  LabTracker.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 1/4/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import CoreLocation
import FutureKit
import EmitterKit

public final class LabTracker: NSObject, CLLocationManagerDelegate {
    private static var _shared: LabTracker?
    public static var shared: LabTracker {
        if _shared == nil {
            _shared = LabTracker()
        }
        return _shared!
    }
    
    
}
