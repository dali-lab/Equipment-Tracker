//
//  Helpers.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 2/22/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import FutureKit

extension Future {
    public var mainThreadFuture: Future<T> {
        let promise = Promise<T>()
        self.onSuccess { (value) in
            DispatchQueue.main.async {
                promise.completeWithSuccess(value)
            }
            }.onFail { (error) in
                DispatchQueue.main.async {
                    promise.completeWithFail(error)
                }
            }.onCancel {
                DispatchQueue.main.async {
                    promise.completeWithCancel()
                }
        }
        return promise.future
    }
}
