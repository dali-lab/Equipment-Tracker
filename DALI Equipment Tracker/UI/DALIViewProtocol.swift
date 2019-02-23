//
//  DALIViewProtocol.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 2/22/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import FutureKit
import EmitterKit

protocol DALIViewProtocol {
    /**
     Preload this view before showing it.
     
     - Note: Gives the callee a chance to do what it needs to before opening.
     */
    func preloadView() -> Future<Any>
}

