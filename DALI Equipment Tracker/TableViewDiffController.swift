//
//  TableViewDiffController.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 2/22/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import UIKit
import FutureKit

/**
 A difference controller for table views. When new data is provided, will animate the table view between states
 
 Requirements:
 - Data backing the table view cells is of a single (Hashable) type
 - Takes over table view data source, so doesn't support table views with other data sources
 */
public class TableViewDiffController<T: Hashable>: NSObject, UITableViewDataSource {
    /// The data as it is shown on the table view
    public private(set) var  data: [[T]]
    /// The table view being controlled
    public private(set) var tableView: UITableView
    /// Delegate to this controller (required to provide cells for each T item in the data)
    public let delegate: TableViewDiffControllerDelegate
    
    /// The animation to be used when doing row opperations
    public var rowAnimation = UITableView.RowAnimation.automatic
    
    /// The currently active batch update promise
    private var activeUpdatePromise: Promise<Void>?
    /// The data (if any) waiting for the currently active update to be over so it can be used
    private var waitingData: [[T]]?
    /// The promise for the waiting update request
    private var waitingUpdatePromise: Promise<Void>?
    
    /**
     Initialize the difference controller
     
     - parameter tableView: The table view to control
     - parameter delegate: The delegate for this controller
     - parameter initialData: The data to start the table view out with
     */
    init(tableView: UITableView, delegate: TableViewDiffControllerDelegate, initialData: [[T]]? = nil) {
        self.data = initialData ?? []
        self.tableView = tableView
        self.delegate = delegate
        
        super.init()
        
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    // MARK: - Public API
    
    /**
     - note: Assumes that number of sections is not changing
     */
    public func update(with newData: [[T]]) -> Future<Void> {
        // If an update is already running, this update request will be postponsed...
        if activeUpdatePromise != nil {
            // Cancel the previous update. Only ever use the most recent request,
            // so if another request was postponed before this one cancel it
            if let waitingUpdatePromise = waitingUpdatePromise {
                waitingUpdatePromise.completeWithCancel()
            }
            
            // Save the information about the update
            waitingUpdatePromise = Promise<Void>()
            waitingData = newData
            
            return waitingUpdatePromise!.future
        }
        
        activeUpdatePromise = Promise<Void>()
        var diffs = newData.enumerated().map { Diff(before: data[$0.offset], after: $0.element) }
        data = newData
        
        // Do ALL the updates!
        tableView.performBatchUpdates({
            for section in 0..<diffs.count {
                var diff = diffs[section]
                
                let insertedIndexPaths = diff.inserted.map { IndexPath(row: $0.to, section: section) }
                let removedIndexPaths = diff.removed.map { IndexPath(row: $0.from, section: section) }
                
                // Insert the added cells
                tableView.insertRows(at: insertedIndexPaths, with: rowAnimation)
                // Delete the removed cells
                tableView.deleteRows(at: removedIndexPaths, with: rowAnimation)
                
                // Move the moved cells
                diff.informedMoved.forEach({ (tuple) in
                    tableView.moveRow(at: IndexPath(row: tuple.start, section: section), to: IndexPath(row: tuple.end, section: section))
                })
            }
        }) { (complete) in
            if complete {
                self.activeUpdatePromise!.completeWithSuccess(Void())
            } else {
                self.activeUpdatePromise!.completeWithFail("Didn't complete batch updates")
            }
        }
        
        // When the active update is done, start the waiting update (if any)
        activeUpdatePromise?.future.onComplete { (_) in
            self.activeUpdatePromise = nil
            
            // If an update is wating...
            if let data = self.waitingData, let promise = self.waitingUpdatePromise {
                // Clean out the stored values
                self.waitingUpdatePromise = nil
                self.waitingData = nil
                
                // And perform the update
                promise.completeUsingFuture(self.update(with: data))
            }
        }
        
        return activeUpdatePromise!.future
    }
    
    // MARK: - UITableViewDelegate
    
    private func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return delegate.tableViewDiffController(tableView, cellForItem: data[indexPath.section][indexPath.row])
    }
    
    // MARK: - Diff opperation
    
    /**
     A struct that describes how an array has changed between two states.
     
     Used by the TableViewDiffController to describe how to change the table view between two data states.
     */
    struct Diff<T:Hashable> {
        /// The data before the change
        public let before: [T]
        /// The data after the change
        public let after: [T]
        
        /**
         Create a difference object with the before and after states
         
         - parameter before: The data before the change
         - parameter after: The data after the change
         */
        init(before: [T], after: [T]) {
            self.before = before
            self.after = after
        }
        
        public lazy var beforeSet: Set<T> = {
            return Set(before)
        }()
        public lazy var afterSet: Set<T> = {
            return Set(after)
        }()
        
        public lazy var allObjects: Set<T> = {
            return beforeSet.union(afterSet)
        }()
        public lazy var removedObjects: Set<T> = {
            return beforeSet.subtracting(afterSet)
        }()
        public lazy var retainedObjects: Set<T> = {
            return beforeSet.intersection(afterSet)
        }()
        public lazy var insertedObjects: Set<T> = {
            return afterSet.subtracting(beforeSet)
        }()
        
        /// The objects that were inserted
        public lazy var inserted: [(object: T, to: Int)] = {
            return insertedObjects.map({ (object: T) -> (object: T, to: Int) in
                return (object, after.firstIndex(of: object)!)
            })
        }()
        
        /// The objects that were removed
        public lazy var removed: [(object: T, from: Int)] = {
            return removedObjects.map({ (object: T) -> (object: T, from: Int) in
                return (object, before.firstIndex(of: object)!)
            })
        }()
        
        /// Before array after removals and additions
        private lazy var informedBefore: [T] = {
            var informedBefore = Array(before)
            inserted.forEach({ (tuple) in
                informedBefore.insert(tuple.object, at: tuple.to)
            })
            removed.forEach({ (tuple) in
                informedBefore.remove(at: tuple.from)
            })
            return informedBefore
        }()
        
        /// After array without the removals and additions
        private lazy var uninformedAfter: [T] = {
            var uninformedAfter = Array(after)
            inserted.forEach({ (tuple) in
                uninformedAfter.remove(at: tuple.to)
            })
            removed.forEach({ (tuple) in
                uninformedAfter.insert(tuple.object, at: tuple.from)
            })
            return informedBefore
        }()
        
        /// The objects that moved after additions and removals with original indicies
        public lazy var moved: [(object: T, start: Int, end: Int)] = {
            return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
                let informedIndexBefore = informedBefore.firstIndex(of: object)!
                let indexBefore = before.firstIndex(of: object)!
                let indexAfter = after.firstIndex(of: object)!
                return informedIndexBefore != indexAfter ? (object, indexBefore, indexAfter) : nil
            })
        }()
        
        /// The objects that have moved assuming that the additions and removals haven't happen yet
        public lazy var uninformedMoved: [(object: T, start: Int, end: Int)] = {
            return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
                let indexBefore = before.firstIndex(of: object)!
                let uninformedIndexAfter = uninformedAfter.firstIndex(of: object)!
                return indexBefore != uninformedIndexAfter ? (object, indexBefore, uninformedIndexAfter) : nil
            })
        }()
        
        /// The objects that have moved even after additions and removals
        public lazy var informedMoved: [(object: T, start: Int, end: Int)] = {
            return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
                let informedIndexBefore = informedBefore.firstIndex(of: object)!
                let indexAfter = after.firstIndex(of: object)!
                return informedIndexBefore != indexAfter ? (object, informedIndexBefore, indexAfter) : nil
            })
        }()
        
        /// Assume no additions or removals, these are the objects which have changed position
        public lazy var naiveMoved: [(object: T, start: Int, end: Int)] = {
            return retainedObjects.compactMap({ (object) -> (T, Int, Int)? in
                let indexBefore = before.firstIndex(of: object)!
                let indexAfter = after.firstIndex(of: object)!
                return indexBefore != indexAfter ? (object, indexBefore, indexAfter) : nil
            })
        }()
    }
}

public protocol TableViewDiffControllerDelegate {
    func tableViewDiffController(_ tableView: UITableView, cellForItem item: Any) -> UITableViewCell
}
