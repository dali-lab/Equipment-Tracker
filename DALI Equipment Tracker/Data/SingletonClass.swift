//
//  SingletonClass.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 1/3/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation

public protocol SingletonClass {
    static var shared: Self { get }
}
